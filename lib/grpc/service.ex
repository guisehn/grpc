defmodule GRPC.Service do
  @moduledoc """
  Define gRPC service used by Stub and Server. You should use `Protobuf` to
  to generate code instead of using this module directly.

  It imports DSL functions like `rpc/3` and `stream/1` for defining the RPC
  functions easily:

      defmodule Greeter.Service do
        use GRPC.Service, name: "helloworld.Greeter"

        rpc :SayHello, HelloRequest, stream(HelloReply)
      end
  """

  defmacro __using__(opts) do
    quote do
      import GRPC.Service, only: [rpc: 3, stream: 1]

      Module.register_attribute(__MODULE__, :rpc_calls, accumulate: true)
      @before_compile GRPC.Service

      def __meta__(:name), do: unquote(opts[:name])
    end
  end

  defmacro __before_compile__(env) do
    rpc_calls = Module.get_attribute(env.module, :rpc_calls)

    quote do
      def __rpc_calls__, do: unquote(rpc_calls |> Macro.escape() |> Enum.reverse())
    end
  end

  defmacro rpc(name, request, reply) do
    quote do
      @rpc_calls {unquote(name), unquote(wrap_stream(request)), unquote(wrap_stream(reply))}
    end
  end

  @doc """
  Specify if the request/reply is streaming.
  """
  def stream(param) do
    quote do: {unquote(param), true}
  end

  @doc false
  def wrap_stream({:stream, _, _} = param) do
    quote do: unquote(param)
  end

  def wrap_stream(param) do
    quote do: {unquote(param), false}
  end

  def grpc_type({_, {_, false}, {_, false}}), do: :unary
  def grpc_type({_, {_, true}, {_, false}}), do: :client_stream
  def grpc_type({_, {_, false}, {_, true}}), do: :server_stream
  def grpc_type({_, {_, true}, {_, true}}), do: :bidirectional_stream
end
