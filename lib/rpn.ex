defmodule Rpn do
  @moduledoc """
  Documentation for Rpn.
  """

  defp eval(ast) do
    {result, _bindings} = Code.eval_quoted(ast)
    result
  end

  defp gen_ast(operator, a, b) do
    operator = if operator == :x, do: :*, else: operator
    {operator, [context: Elixir, import: Kernel], [b, a]}
  end

  defp calc(e, mem) when is_atom(e) do
    {[n1, n2], rest} = mem |> Enum.split(2)
    [eval(gen_ast(e, n1, n2)) | rest]
  end

  defp calc(e, mem) do
    [e | mem]
  end

  use GenServer

  @doc """
  Starts the registry.
  """
  def start(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def peek(server) do
    GenServer.call(server, {:peek})
  end

  def push(server, element) do
    GenServer.cast(server, {:push, element})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:peek}, _from, mem) do
    {:reply, mem, mem}
  end

  def handle_cast({:push, e}, mem) do
    {:noreply, calc(e, mem)}
  end
end
