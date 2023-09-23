defmodule QuorumTest do
  use ExUnit.Case
  doctest Quorum

  test "greets the world" do
    assert Quorum.hello() == :world
  end
end
