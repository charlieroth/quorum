defmodule Quorum.Message do
  @enforce_keys [:type, :data]
  defstruct [:type, :data]

  @type t :: %__MODULE__{
          type: atom(),
          data: map()
        }
end
