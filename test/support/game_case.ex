defmodule Poker.GameCase do
  @moduledoc """
  This module defines the setup for tests requiring
  helpers for setting up a game easily
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Poker.DataCase
      use Poker.GameHelpers

      import Poker.GameHelpers
    end
  end
end
