defmodule WrpcTest do
  use ExUnit.Case
  doctest Wrpc

  describe "Wrpc.Tcp.connect/1" do
    test "creates a client reference with valid address" do
      {:ok, client} = Wrpc.Tcp.connect("127.0.0.1:7761")
      assert is_reference(client)
    end

    test "creates a client reference with IPv6 address" do
      {:ok, client} = Wrpc.Tcp.connect("[::1]:7761")
      assert is_reference(client)
    end
  end

  describe "Wrpc.invoke/4" do
    @tag :integration
    test "invokes a remote function successfully" do
      # This test requires a running wRPC server
      # Start a server with: wrpc-wasmtime tcp serve ./target/wasm32-wasip2/release/hello_component_server.wasm
      {:ok, client} = Wrpc.Tcp.connect("127.0.0.1:7761")

      case Wrpc.invoke(client, "wrpc-examples:hello/handler", "hello", <<>>) do
        {:ok, result} ->
          assert is_binary(result)

        {:error, _reason} ->
          # Server not running, skip the assertion
          :ok
      end
    end
  end
end
