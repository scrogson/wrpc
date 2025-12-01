defmodule Wrpc do
  @moduledoc """
  Elixir bindings for wRPC - WebAssembly component-native RPC framework.

  wRPC facilitates execution of arbitrary functionality defined in WIT
  (WebAssembly Interface Types) over network or other means of communication.

  This library provides a Rustler NIF that wraps the wRPC Rust transport layer,
  allowing Elixir applications to invoke WIT functions via TCP transport.

  ## Example

      # Create a TCP client connection
      {:ok, client} = Wrpc.Tcp.connect("127.0.0.1:7761")

      # Invoke a remote function
      {:ok, result} = Wrpc.invoke(client, "wrpc-examples:hello/handler", "hello", <<>>)

  ## Architecture

  wRPC uses a client-server model where:
  - **Clients** invoke WIT functions over the wRPC transport
  - **Servers** serve WIT functions over the wRPC transport

  The transport layer handles multiplexed bidirectional byte streams for
  efficient communication.
  """

  alias Wrpc.Native

  @type client :: reference()
  @type instance :: String.t()
  @type func :: String.t()
  @type params :: binary()
  @type result :: {:ok, binary()} | {:error, term()}

  @doc """
  Invokes a remote WIT function via wRPC.

  ## Parameters

    * `client` - A client reference obtained from `Wrpc.Tcp.connect/1`
    * `instance` - The WIT instance name (e.g., "wrpc-examples:hello/handler")
    * `func` - The function name to invoke (e.g., "hello")
    * `params` - Binary-encoded parameters (can be empty `<<>>` for no params)

  ## Returns

    * `{:ok, binary}` - The binary-encoded result on success
    * `{:error, reason}` - An error tuple on failure

  ## Example

      {:ok, client} = Wrpc.Tcp.connect("127.0.0.1:7761")
      {:ok, result} = Wrpc.invoke(client, "wrpc-examples:hello/handler", "hello", <<>>)

  """
  @spec invoke(client(), instance(), func(), params()) :: result()
  def invoke(client, instance, func, params) when is_reference(client) and is_binary(instance) and is_binary(func) and is_binary(params) do
    Native.invoke(client, instance, func, params)
  end
end
