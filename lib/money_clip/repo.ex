defmodule MoneyClip.Repo do
  use Ecto.Repo,
    otp_app: :money_clip,
    adapter: Ecto.Adapters.Postgres
end
