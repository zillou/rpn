defmodule RpnTest do
  use ExUnit.Case

  test "starts with an empty stack" do
    {:ok, pid} = Rpn.start
    assert Rpn.peek(pid) == []
  end

  test "pushing onto the stack" do
    {:ok, pid} = Rpn.start
    Rpn.push(pid, 5)
    assert Rpn.peek(pid) == [5]
    Rpn.push(pid, 1)
    assert Rpn.peek(pid) == [1, 5]
  end

  test "adding" do
    {:ok, pid} = Rpn.start
    Rpn.push(pid, 5)
    Rpn.push(pid, 1)
    Rpn.push(pid, :+)
    assert Rpn.peek(pid) == [6]
  end

  test "wikipedia example" do
    {:ok, pid} = Rpn.start
    Rpn.push(pid, 5)
    Rpn.push(pid, 1)
    Rpn.push(pid, 2)
    Rpn.push(pid, :+)
    Rpn.push(pid, 4)
    Rpn.push(pid, :x)
    Rpn.push(pid, :+)
    Rpn.push(pid, 3)
    Rpn.push(pid, :-)

    assert Rpn.peek(pid) == [14]
  end

  @tag :capture_log
  test "invalid operator" do
    Process.flag(:trap_exit, true)
    {:ok, pid} = Rpn.start

    assert {{%UndefinedFunctionError{message: "operator xx/2 is not supported"}, _},
            {GenServer, :call, [^pid, {:peek}, _]}} =
      catch_exit((fn ->
        Rpn.push(pid, 1)
        Rpn.push(pid, 2)
        Rpn.push(pid, :xx)
        Rpn.peek(pid)
      end).())
  end

  @tag :capture_log
  test "wrong args" do
    Process.flag(:trap_exit, true)
    {:ok, pid} = Rpn.start

    assert {{%UndefinedFunctionError{message: "operator */1 is not supported"}, _},
            {GenServer, :call, [^pid, {:peek}, _]}} =
      catch_exit((fn ->
        Rpn.push(pid, 1)
        Rpn.push(pid, :*)
        Rpn.peek(pid)
      end).())
  end
end
