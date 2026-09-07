defmodule Medcamp.FeedbackFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Feedback` context.
  """

  @doc """
  Generate a patient_feedback.
  """
  def patient_feedback_fixture(attrs \\ %{}) do
    {:ok, patient_feedback} =
      attrs
      |> Enum.into(%{
        age: 42,
        areas_to_improve: "some areas_to_improve",
        cleanliness_rating: 4,
        department: "opd",
        diagnosis_explanation_rating: 4,
        gender: "male",
        ip_address: "some ip_address",
        lab_service_rating: 4,
        liked_most: "some liked_most",
        medication_availability_rating: 4,
        name: "some name",
        other_comments: "some other_comments",
        overall_satisfaction_rating: 4,
        privacy_rating: 4,
        registration_rating: 4,
        staff_courtesy_rating: 4,
        submitted_at: ~N[2025-06-22 07:57:00],
        visit_date: ~D[2025-06-22],
        waiting_time_rating: 4,
        would_recommend: "some would_recommend"
      })
      |> Medcamp.Feedback.create_patient_feedback()

    patient_feedback
  end
end
