# wRPC for Elixir

Elixir NIF bindings for [wRPC](https://github.com/bytecodealliance/wrpc) - WebAssembly component-native RPC framework based on [WIT](https://component-model.bytecodealliance.org/design/wit.html).

## About

This library provides Elixir bindings for the wRPC transport layer through a Rustler NIF. wRPC facilitates execution of arbitrary functionality defined in WIT over network or other means of communication.

Main use cases for wRPC are:
- Out-of-tree WebAssembly runtime plugins
- Distributed WebAssembly component communication
- General-purpose RPC framework

## Installation

Add `wrpc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:wrpc, "~> 0.1.0"}
  ]
end
```

### Requirements

- Elixir >= 1.14
- Erlang/OTP >= 25
- Rust >= 1.82 (for compiling the NIF)

## Usage

### TCP Transport

```elixir
# Create a TCP client connection
{:ok, client} = Wrpc.Tcp.connect("127.0.0.1:7761")

# Invoke a remote WIT function
{:ok, result} = Wrpc.invoke(client, "wrpc-examples:hello/handler", "hello", <<>>)

# IPv6 is also supported
{:ok, client} = Wrpc.Tcp.connect("[::1]:7761")
```

### Running with a wRPC Server

To test the bindings, you can run a wRPC server using the official wRPC tools:

```bash
# Build and run a hello world server
wrpc-wasmtime tcp serve ./target/wasm32-wasip2/release/hello_component_server.wasm
```

See the [wRPC examples](https://github.com/bytecodealliance/wrpc/tree/main/examples) for more server implementations.

## API Reference

### `Wrpc.Tcp.connect/1`

Creates a new TCP client that connects to the given address.

```elixir
@spec connect(address :: String.t()) :: {:ok, client()} | {:error, term()}
```

### `Wrpc.invoke/4`

Invokes a remote WIT function via wRPC.

```elixir
@spec invoke(client(), instance(), func(), params()) :: {:ok, binary()} | {:error, term()}
```

Parameters:
- `client` - A client reference obtained from `Wrpc.Tcp.connect/1`
- `instance` - The WIT instance name (e.g., "wrpc-examples:hello/handler")
- `func` - The function name to invoke (e.g., "hello")
- `params` - Binary-encoded parameters (can be empty `<<>>` for no params)

## Development

### Building

```bash
# Fetch dependencies (requires network access)
mix deps.get

# Compile the project (this will also build the Rust NIF)
mix compile
```

### Running Tests

```bash
# Run all tests
mix test

# Run integration tests (requires a running wRPC server)
mix test --include integration
```

## Architecture

The library is structured as follows:

- `lib/wrpc.ex` - Main module with the `invoke/4` function
- `lib/wrpc/tcp.ex` - TCP transport module
- `lib/wrpc/native.ex` - Rustler NIF bindings
- `native/wrpc_nif/` - Rust crate implementing the NIF

The Rust NIF wraps the `wrpc-transport` crate and exposes it to Elixir through Rustler.

## License

Apache-2.0 WITH LLVM-exception

See [LICENSE](LICENSE) for details.

## Related Projects

- [wRPC](https://github.com/bytecodealliance/wrpc) - The official wRPC implementation
- [Rustler](https://github.com/rusterlium/rustler) - Safe Rust bridge for creating Erlang NIFs