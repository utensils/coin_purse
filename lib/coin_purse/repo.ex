defmodule CoinPurse.Repo do
  use Ecto.Repo,
    otp_app: :coin_purse,
    adapter: Ecto.Adapters.Postgres
end
