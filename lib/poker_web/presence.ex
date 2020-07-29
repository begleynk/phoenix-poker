defmodule PokerWeb.Presence do
  use Phoenix.Presence, otp_app: :poker, pubsub_server: Poker.PubSub
end
