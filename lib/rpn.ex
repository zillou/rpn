defmodule Rpn do
  @moduledoc """
  Documentation for Rpn.
  """

  defp eval(ast) do
    {result, _bindings} = Code.eval_quoted(ast)
    result
  end

  @op_alias %{
    x: {:*, :kernel},
    "**": {:pow, :math},
    ^: {:pow, :math}
  }

  defp gen_ast(operator, a, b) do
    cond do
      Map.has_key?(@op_alias, operator) ->
        {op, namespace} = @op_alias[operator]
        ast(namespace, op, a, b)
      :erlang.function_exported(:math, operator, 2) ->
        ast(:math, operator, a, b)
      :erlang.function_exported(Kernel, operator, 2) ->
        ast(:kernel, operator, a, b)
      true ->
        raise UndefinedFunctionError, message: "operator #{operator}/2 is not supported"
    end
  end

  defp ast(:kernel, operator, a, b) do
	{operator, [context: Elixir, import: Kernel], [b, a]}
  end

  defp ast(:math, operator, a, b) do
	{{:., [], [:math, operator]}, [], [b, a]}
  end

  defp calc(e, mem) when is_atom(e) and length(mem) < 2 do
    raise UndefinedFunctionError, message: "operator #{e}/1 is not supported"
  end

  defp calc(e, mem) when is_atom(e) do
    [n1, n2 | rest] = mem
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
