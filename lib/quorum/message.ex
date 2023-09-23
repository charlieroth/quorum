defmodule Quorum.Message do
  @enforce_keys [:poll_id, :data]
  defstruct [:poll_id, :data]

  @type t :: %__MODULE__{
          poll_id: String.t(),
          data: map()
        }
end
