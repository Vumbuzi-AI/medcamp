defmodule Medcamp.FeedbackTest do
  use Medcamp.DataCase

  alias Medcamp.Feedback

  describe "patient_feedbacks" do
    alias Medcamp.Feedback.PatientFeedback

    import Medcamp.FeedbackFixtures

    @invalid_attrs %{
      age: 200,
      gender: "invalid gender",
      department: "invalid department",
      registration_rating: 42,
      staff_courtesy_rating: 42,
      waiting_time_rating: 42,
      cleanliness_rating: 42,
      privacy_rating: 42,
      diagnosis_explanation_rating: 42,
      medication_availability_rating: 42,
      lab_service_rating: 42,
      overall_satisfaction_rating: 42
    }

    test "list_patient_feedbacks/0 returns all patient_feedbacks" do
      patient_feedback = patient_feedback_fixture()
      assert Feedback.list_patient_feedbacks() == [patient_feedback]
    end

    test "get_patient_feedback!/1 returns the patient_feedback with given id" do
      patient_feedback = patient_feedback_fixture()
      assert Feedback.get_patient_feedback!(patient_feedback.id) == patient_feedback
    end

    test "create_patient_feedback/1 with valid data creates a patient_feedback" do
      valid_attrs = %{
        name: "some name",
        age: 42,
        gender: "male",
        visit_date: ~D[2025-06-22],
        department: "opd",
        department_other: "some department_other",
        registration_rating: 4,
        staff_courtesy_rating: 4,
        waiting_time_rating: 4,
        cleanliness_rating: 4,
        privacy_rating: 4,
        diagnosis_explanation_rating: 4,
        medication_availability_rating: 4,
        lab_service_rating: 4,
        overall_satisfaction_rating: 4,
        liked_most: "some liked_most",
        areas_to_improve: "some areas_to_improve",
        other_comments: "some other_comments",
        would_recommend: "some would_recommend",
        submitted_at: ~N[2025-06-22 07:57:00],
        ip_address: "some ip_address"
      }

      assert {:ok, %PatientFeedback{} = patient_feedback} =
               Feedback.create_patient_feedback(valid_attrs)

      assert patient_feedback.name == "some name"
      assert patient_feedback.age == 42
      assert patient_feedback.gender == "male"
      assert patient_feedback.visit_date == ~D[2025-06-22]
      assert patient_feedback.department == "opd"
      assert patient_feedback.department_other == "some department_other"
      assert patient_feedback.registration_rating == 4
      assert patient_feedback.staff_courtesy_rating == 4
      assert patient_feedback.waiting_time_rating == 4
      assert patient_feedback.cleanliness_rating == 4
      assert patient_feedback.privacy_rating == 4
      assert patient_feedback.diagnosis_explanation_rating == 4
      assert patient_feedback.medication_availability_rating == 4
      assert patient_feedback.lab_service_rating == 4
      assert patient_feedback.overall_satisfaction_rating == 4
      assert patient_feedback.liked_most == "some liked_most"
      assert patient_feedback.areas_to_improve == "some areas_to_improve"
      assert patient_feedback.other_comments == "some other_comments"
      assert patient_feedback.would_recommend == "some would_recommend"
      assert patient_feedback.submitted_at == ~N[2025-06-22 07:57:00]
      assert patient_feedback.ip_address == "some ip_address"
    end

    test "create_patient_feedback/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feedback.create_patient_feedback(@invalid_attrs)
    end

    test "update_patient_feedback/2 with valid data updates the patient_feedback" do
      patient_feedback = patient_feedback_fixture()

      update_attrs = %{
        name: "some updated name",
        age: 43,
        gender: "female",
        visit_date: ~D[2025-06-23],
        department: "inpatient",
        department_other: "some updated department_other",
        registration_rating: 5,
        staff_courtesy_rating: 5,
        waiting_time_rating: 5,
        cleanliness_rating: 5,
        privacy_rating: 5,
        diagnosis_explanation_rating: 5,
        medication_availability_rating: 5,
        lab_service_rating: 5,
        overall_satisfaction_rating: 5,
        liked_most: "some updated liked_most",
        areas_to_improve: "some updated areas_to_improve",
        other_comments: "some updated other_comments",
        would_recommend: "some updated would_recommend",
        submitted_at: ~N[2025-06-23 07:57:00],
        ip_address: "some updated ip_address"
      }

      assert {:ok, %PatientFeedback{} = patient_feedback} =
               Feedback.update_patient_feedback(patient_feedback, update_attrs)

      assert patient_feedback.name == "some updated name"
      assert patient_feedback.age == 43
      assert patient_feedback.gender == "female"
      assert patient_feedback.visit_date == ~D[2025-06-23]
      assert patient_feedback.department == "inpatient"
      assert patient_feedback.department_other == "some updated department_other"
      assert patient_feedback.registration_rating == 5
      assert patient_feedback.staff_courtesy_rating == 5
      assert patient_feedback.waiting_time_rating == 5
      assert patient_feedback.cleanliness_rating == 5
      assert patient_feedback.privacy_rating == 5
      assert patient_feedback.diagnosis_explanation_rating == 5
      assert patient_feedback.medication_availability_rating == 5
      assert patient_feedback.lab_service_rating == 5
      assert patient_feedback.overall_satisfaction_rating == 5
      assert patient_feedback.liked_most == "some updated liked_most"
      assert patient_feedback.areas_to_improve == "some updated areas_to_improve"
      assert patient_feedback.other_comments == "some updated other_comments"
      assert patient_feedback.would_recommend == "some updated would_recommend"
      assert patient_feedback.submitted_at == ~N[2025-06-23 07:57:00]
      assert patient_feedback.ip_address == "some updated ip_address"
    end

    test "update_patient_feedback/2 with invalid data returns error changeset" do
      patient_feedback = patient_feedback_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Feedback.update_patient_feedback(patient_feedback, @invalid_attrs)

      assert patient_feedback == Feedback.get_patient_feedback!(patient_feedback.id)
    end

    test "delete_patient_feedback/1 deletes the patient_feedback" do
      patient_feedback = patient_feedback_fixture()
      assert {:ok, %PatientFeedback{}} = Feedback.delete_patient_feedback(patient_feedback)

      assert_raise Ecto.NoResultsError, fn ->
        Feedback.get_patient_feedback!(patient_feedback.id)
      end
    end

    test "change_patient_feedback/1 returns a patient_feedback changeset" do
      patient_feedback = patient_feedback_fixture()
      assert %Ecto.Changeset{} = Feedback.change_patient_feedback(patient_feedback)
    end
  end
end
