defmodule ParklotRsvp.Schedule.ReservationSchedulerTest do
  use ParklotRsvp.DataCase
  use ExMatchers
  use Bamboo.Test

  import ParklotRsvp.Fixtures

  alias ParklotRsvp.Schedule.ReservationScheduler
  alias ParklotRsvpWeb.ReservationEmail
  alias ParklotRsvp.Schedule.TokenMock
  alias ParklotRsvp.Schedule.GoogleApiMock

  alias Http.Mock

  import Mox

  # setup :verify_on_exit!

  @tomorrow Timex.shift(Timex.to_date(Timex.now("America/Buenos_Aires")), days: 1)
  @past_tomorrow Timex.shift(Timex.to_date(Timex.now("America/Buenos_Aires")), days: 2)

  setup do
    Mock
      |> stub(:post, fn _, _, _ -> {:ok, %HTTPoison.Response{status_code: 200, body: ""}} end)

    ParklotRsvp.Schedule.GoogleConnectionMock
      |> stub(:new, fn _ -> %Tesla.Client{} end )

    GoogleApiMock
      |> stub(:calendar_events_insert, fn _, _, _ -> {:ok, %GoogleApi.Calendar.V3.Model.Event{}} end)

    TokenMock
      |> stub(:for_scope, fn _ -> {:ok, %{token: ""}} end)

    reservation_fixture(%{user: "john", notes: nil, scheduled_at: @tomorrow})
    reservation_fixture(%{user: "paul", notes: nil, scheduled_at: @tomorrow})
    reservation_fixture(%{user: "george", notes: nil, scheduled_at: @tomorrow})
    best_candidate = reservation_fixture(%{user: "ringo", notes: "work related", scheduled_at: @tomorrow})

    {:ok, best_candidate: best_candidate}
  end

  test "schedule the next reservation" do
    confirmed_reservation = ReservationScheduler.schedule_next_reservation()

    expect confirmed_reservation.confirmed, to: eq(true)
    expect confirmed_reservation.user, to: eq("ringo")
  end

  test "schedule the next reservation sends email" do
    confirmed_reservation = ReservationScheduler.schedule_next_reservation()

    assert_delivered_email ReservationEmail.reservation_confirmed_email(
      ["john@10pines.com",  "paul@10pines.com", "george@10pines.com", "ringo@10pines.com"], confirmed_reservation)
  end

  test "schedule the next reservation notifies slack channel" do
    Mock
      |> expect(:post, 1, fn _, payload, _ ->
        decoded_payload = Poison.decode!(payload)
        assert decoded_payload["text"] == "Reserva confirmada!"
        {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
      end)

    ReservationScheduler.schedule_next_reservation()
  end

  test "schedule the next reservation adds event to calendar" do
    GoogleApiMock
      |> expect(:calendar_events_insert, 1, fn _, _, _ ->
      {:ok, %GoogleApi.Calendar.V3.Model.Event{}}
    end)

    ReservationScheduler.schedule_next_reservation()

    verify!(GoogleApiMock)
  end

  test "nothing to schedule returns empty Schedule" do
    Mock
      |> expect(:post, 1, fn _, payload, _ ->
        decoded_payload = Poison.decode!(payload)
        assert decoded_payload["text"] == "No hay ninguna reserva para el dia [#{@past_tomorrow}]. Podes tomar la cochera y avisar por Whatsapp!"
        {:ok, %HTTPoison.Response{status_code: 200, body: ""}}
      end)
    ReservationScheduler.schedule_next_reservation(@past_tomorrow)
  end

  test "nothing to schedule notifies slack channel" do
    # TODO
  end
end
