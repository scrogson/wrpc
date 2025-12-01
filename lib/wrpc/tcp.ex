defmodule Wrpc.Tcp do
  @moduledoc """
  TCP transport for wRPC.

  This module provides functions for creating TCP-based wRPC clients
  that can invoke remote WIT functions.

  ## Example

      # Connect to a wRPC server on localhost
      {:ok, client} = Wrpc.Tcp.connect("127.0.0.1:7761")

      # Connect with IPv6
      {:ok, client} = Wrpc.Tcp.connect("[::1]:7761")

  """

  alias Wrpc.Native

  @type address :: String.t()
  @type client :: reference()

  @doc """
  Creates a new TCP client that connects to the given address.

  The address should be in the format "host:port" for IPv4 or "[host]:port" for IPv6.

  ## Parameters

    * `address` - The server address to connect to (e.g., "127.0.0.1:7761")

  ## Returns

    * `{:ok, client}` - A client reference on success
    * `{:error, reason}` - An error tuple on failure

  ## Example

      {:ok, client} = Wrpc.Tcp.connect("127.0.0.1:7761")

  """
  @spec connect(address()) :: {:ok, client()} | {:error, term()}
  def connect(address) when is_binary(address) do
    Native.tcp_client_new(address)
  end
end
