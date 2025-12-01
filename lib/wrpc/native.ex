defmodule Wrpc.Native do
  @moduledoc false

  use Rustler,
    otp_app: :wrpc,
    crate: :wrpc_nif

  # NIF stubs - these are overwritten by the Rustler NIF when loaded

  @doc false
  def tcp_client_new(_address), do: :erlang.nif_error(:nif_not_loaded)

  @doc false
  def invoke(_client, _instance, _func, _params), do: :erlang.nif_error(:nif_not_loaded)
end
