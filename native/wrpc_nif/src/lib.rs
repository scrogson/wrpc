//! Rustler NIF for wRPC - Elixir bindings for wRPC transport layer.
//!
//! This crate provides Native Implemented Functions (NIFs) that wrap the wRPC
//! Rust transport library, allowing Elixir applications to invoke WIT functions
//! via TCP transport.

use bytes::Bytes;
use rustler::{Atom, Binary, Env, Error, NifResult, OwnedBinary, ResourceArc};
use std::sync::Arc;
use tokio::runtime::Runtime;
use wrpc_transport::tcp::Client as TcpClient;
use wrpc_transport::Invoke;

mod atoms {
    rustler::atoms! {
        ok,
        error,
        connection_failed,
        invocation_failed,
        invalid_address,
        runtime_error,
    }
}

/// Resource wrapper for the TCP client
struct TcpClientResource {
    client: TcpClient<String>,
    runtime: Arc<Runtime>,
}

// Implement Send and Sync markers for the resource
// This is safe because we use async/await properly with the runtime
unsafe impl Send for TcpClientResource {}
unsafe impl Sync for TcpClientResource {}

/// Lazy-initialized global Tokio runtime
fn get_runtime() -> Arc<Runtime> {
    use std::sync::OnceLock;
    static RUNTIME: OnceLock<Arc<Runtime>> = OnceLock::new();

    RUNTIME
        .get_or_init(|| {
            Arc::new(
                tokio::runtime::Builder::new_multi_thread()
                    .enable_all()
                    .worker_threads(4)
                    .thread_name("wrpc-nif-worker")
                    .build()
                    .expect("Failed to create Tokio runtime"),
            )
        })
        .clone()
}

/// Create a new TCP client that can connect to the given address.
///
/// # Arguments
///
/// * `address` - The server address in "host:port" format
///
/// # Returns
///
/// * `{:ok, reference}` - A resource reference to the client on success
/// * `{:error, reason}` - An error tuple on failure
#[rustler::nif]
fn tcp_client_new(address: String) -> NifResult<(Atom, ResourceArc<TcpClientResource>)> {
    // Validate the address format (basic check)
    if address.is_empty() {
        return Err(Error::Term(Box::new(atoms::invalid_address())));
    }

    let runtime = get_runtime();
    let client = TcpClient::from(address);

    let resource = TcpClientResource { client, runtime };

    Ok((atoms::ok(), ResourceArc::new(resource)))
}

/// Invoke a remote WIT function via the TCP client.
///
/// # Arguments
///
/// * `client` - A resource reference to the TCP client
/// * `instance` - The WIT instance name (e.g., "wrpc-examples:hello/handler")
/// * `func` - The function name to invoke
/// * `params` - Binary-encoded parameters
///
/// # Returns
///
/// * `{:ok, binary}` - The result data on success
/// * `{:error, reason}` - An error tuple on failure
#[rustler::nif(schedule = "DirtyCpu")]
fn invoke<'a>(
    env: Env<'a>,
    client: ResourceArc<TcpClientResource>,
    instance: String,
    func: String,
    params: Binary<'a>,
) -> NifResult<(Atom, Binary<'a>)> {
    let params_bytes = Bytes::copy_from_slice(params.as_slice());

    // Run the async invoke in the Tokio runtime
    let result = client.runtime.block_on(async {
        use tokio::io::AsyncWriteExt;

        // Define paths as empty slice for no streaming
        let paths: &[Box<[Option<usize>]>] = &[];

        // Invoke the function
        let (mut outgoing, mut incoming) = client
            .client
            .invoke((), &instance, &func, params_bytes, paths)
            .await
            .map_err(|e| format!("invocation failed: {}", e))?;

        // Shutdown the outgoing stream
        outgoing
            .shutdown()
            .await
            .map_err(|e| format!("shutdown failed: {}", e))?;

        // Read the result from the incoming stream
        use tokio::io::AsyncReadExt;
        let mut result = Vec::new();
        incoming
            .read_to_end(&mut result)
            .await
            .map_err(|e| format!("read failed: {}", e))?;

        Ok::<Vec<u8>, String>(result)
    });

    match result {
        Ok(data) => {
            let mut binary = OwnedBinary::new(data.len()).ok_or(Error::Term(Box::new(
                atoms::runtime_error(),
            )))?;
            binary.as_mut_slice().copy_from_slice(&data);
            Ok((atoms::ok(), binary.release(env)))
        }
        Err(msg) => Err(Error::Term(Box::new((atoms::error(), msg)))),
    }
}

/// Initialize the NIF module.
#[allow(non_local_definitions)]
fn load(env: Env, _info: rustler::Term) -> bool {
    let _ = rustler::resource!(TcpClientResource, env);
    true
}

rustler::init!("Elixir.Wrpc.Native", load = load);
