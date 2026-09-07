defmodule Medcamp.Blogs.DefaultPosts do
  @moduledoc false

  def list do
    [
      %{
        slug: "first-outpatient-visit",
        category: "Patient Guide",
        title: "What to Expect at Your First Outpatient Visit to GHCE",
        author_name: "GHCE Clinical Team",
        excerpt:
          "A practical guide to registration, triage, consultation, and pharmacy so your first visit feels clear from the moment you arrive.",
        intro:
          "A first hospital visit can feel unfamiliar, especially when you are already worried about your health. At GHCE, we try to make each step easy to follow so patients spend less time confused and more time getting care.",
        hero_image_url:
          "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1400&q=80",
        hero_image_alt: "A patient being welcomed at the GHCE outpatient reception desk",
        published_at: ~U[2026-05-01 00:00:00Z],
        status: "published",
        sections: [
          %{
            title: "Arriving at GHCE",
            body:
              "When you arrive, our reception team confirms your details and creates or retrieves your patient record. That record stays with you across visits so clinicians can see your history and avoid starting from scratch each time.\n\nBring a valid ID if you have one, any previous clinic booklets, and a short list of medicines you are currently using. That small preparation helps the team register you faster and guide you to the right service.",
            quote:
              "Every patient deserves a visit that feels organised, respectful, and easy to understand.",
            position: 0
          },
          %{
            title: "Triage Comes Before Treatment",
            body:
              "Before you see a clinician, our nursing team usually checks the essentials: temperature, blood pressure, pulse, and the reason for your visit. This step helps us spot urgent cases early and make sure each patient is seen in the right order.\n\nIf your symptoms need immediate attention, the team can escalate your case quickly. If not, triage still gives the clinician a better starting point for your consultation.",
            image_url:
              "https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=1200&q=80",
            image_alt: "A nurse checking a patient's vital signs before consultation",
            image_caption:
              "Triage helps the clinical team understand urgency before the consultation begins.",
            position: 1
          },
          %{
            title: "The Consultation",
            body:
              "During consultation, the clinician listens to your concerns, reviews your history, and explains the next step in plain language. If tests are needed, they are requested clearly. If treatment is needed, the prescription is documented in a way the next team can verify.\n\nPatients often leave feeling calmer when they understand not just what is happening, but why. We encourage questions, especially if this is your first visit or you are managing a long-term condition.",
            image_url:
              "https://images.unsplash.com/photo-1516549655669-df4d7d3f34d5?auto=format&fit=crop&w=1200&q=80",
            image_alt: "A clinician consulting with a patient in an outpatient room",
            image_caption:
              "Good consultations combine clinical accuracy with clear patient communication.",
            position: 2
          },
          %{
            title: "After Your Visit",
            body:
              "The visit does not end when the consultation is over. Prescriptions move to the pharmacy with a clear written trail, lab requests are documented, and follow-up instructions are explained before you leave.\n\nIf you need a review appointment, wound care, a repeat visit, or a specialist referral, our team helps coordinate that next step so you are not left guessing what happens after the clinic door.",
            image_url:
              "https://images.unsplash.com/photo-1580281657527-47d2d9a533fd?auto=format&fit=crop&w=1200&q=80",
            image_alt:
              "GHCE pharmacy where every prescription is verified before it reaches the patient",
            image_caption:
              "GHCE pharmacy where every prescription is verified before it reaches the patient.",
            position: 3
          }
        ]
      },
      %{
        slug: "safe-medicine-dispensing",
        category: "Patient Safety",
        title: "Why Safe Medicine Dispensing Starts Before the Pharmacy",
        author_name: "GHCE Clinical Team",
        excerpt:
          "How verified prescription workflows at GHCE protect patients from medication errors, every single day.",
        intro:
          "Medication safety begins long before a patient reaches the dispensing window. At GHCE, prescribing, review, dispensing, and counselling are connected so every medicine has a clear clinical story behind it.",
        hero_image_url:
          "https://images.unsplash.com/photo-1584515933487-779824d29309?auto=format&fit=crop&w=1400&q=80",
        hero_image_alt: "A pharmacist reviewing medicines before dispensing them to a patient",
        published_at: ~U[2026-04-01 00:00:00Z],
        status: "published",
        sections: [
          %{
            title: "Verified Workflows",
            body:
              "At GHCE, a prescription is not treated as a loose instruction. It is part of a structured workflow that connects the clinician's diagnosis, the patient's record, and the pharmacy's verification process.\n\nThat means pharmacists are not guessing what was intended. They receive documented orders that can be checked for dose, timing, duplication, and suitability before anything reaches the patient.",
            quote:
              "Safer dispensing happens when every handoff is traceable and every question can be clarified quickly.",
            position: 0
          },
          %{
            title: "Prescribing With Context",
            body:
              "A medicine order is safer when it is written in the context of the patient's history. Allergies, recent treatment, age, pregnancy status, and ongoing conditions all shape whether a prescription is appropriate.\n\nWhen clinicians document carefully, pharmacists can verify with confidence. When questions arise, the workflow makes it easier to confirm details instead of making assumptions.",
            image_url:
              "https://images.unsplash.com/photo-1579154204601-01588f351e67?auto=format&fit=crop&w=1200&q=80",
            image_alt: "A clinician reviewing a patient file before writing a prescription",
            image_caption:
              "Medication safety improves when the prescription is grounded in the full patient picture.",
            position: 1
          },
          %{
            title: "The Pharmacy Double-Check",
            body:
              "Dispensing is not just counting tablets. It includes checking the medicine, the strength, the quantity, and the instructions against the original order. If anything is unclear, the pharmacy team resolves it before the medicine is handed over.\n\nThis step matters because small errors can have serious consequences. A disciplined double-check culture protects both patients and clinicians.",
            image_url:
              "https://images.unsplash.com/photo-1585435557343-3b092031a831?auto=format&fit=crop&w=1200&q=80",
            image_alt: "A pharmacist checking medication labels and quantities",
            image_caption:
              "Each prescription should be verified before it is dispensed to the patient.",
            position: 2
          },
          %{
            title: "Counselling Patients Clearly",
            body:
              "Even the right medicine can fail if the patient leaves unsure how to use it. That is why counselling matters. Patients need simple explanations about dose, timing, side effects, and what to do if symptoms change.\n\nGood counselling turns dispensing into safe use. It gives patients the confidence to continue treatment correctly once they are back home.",
            position: 3
          },
          %{
            title: "Why This Matters Daily",
            body:
              "Medication errors are rarely dramatic at the start. They often begin with hurried writing, missing details, or assumptions during handoff. Building a dependable system reduces those weak points.\n\nAt GHCE, our goal is not only to dispense medicines quickly, but to dispense them safely, consistently, and with the right support around the patient.",
            position: 4
          }
        ]
      },
      %{
        slug: "maternal-care-stories",
        category: "Maternal Health",
        title: "Maternal Care at GHCE: What Mothers Are Saying",
        author_name: "GHCE Clinical Team",
        excerpt:
          "Real experiences from patients who chose GHCE for antenatal care, delivery, and postnatal follow-up.",
        intro:
          "Pregnancy care is not only about clinical checks. It is also about reassurance, preparation, and making mothers feel seen at every stage. The stories we hear most often are about calm communication, close follow-up, and a team that notices the details.",
        hero_image_url:
          "https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?auto=format&fit=crop&w=1400&q=80",
        hero_image_alt: "A mother holding her newborn after receiving care at GHCE",
        published_at: ~U[2026-03-01 00:00:00Z],
        status: "published",
        sections: [
          %{
            title: "Care That Feels Personal",
            body:
              "Many mothers describe their experience at GHCE in the same way: they felt listened to. That feeling often comes from small but important moments such as having questions answered clearly, understanding what each visit is for, and being told when to return.\n\nPersonal care does not have to be complicated. It often looks like consistency, patience, and a team that remembers you from one visit to the next.",
            quote:
              "When mothers feel informed and supported, they approach each stage of care with more confidence.",
            position: 0
          },
          %{
            title: "Antenatal Visits That Build Confidence",
            body:
              "Routine antenatal care helps mothers track the progress of pregnancy, identify risks early, and prepare for delivery with fewer surprises. It also creates a dependable relationship between the patient and the care team.\n\nAt each visit, mothers can talk through symptoms, nutrition, medicines, warning signs, and practical plans for delivery. That steady rhythm of follow-up is one of the biggest reasons patients say they feel safer.",
            image_url:
              "https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=1200&q=80",
            image_alt: "A pregnant mother speaking with a maternal care clinician",
            image_caption:
              "Regular antenatal visits give mothers a chance to ask questions and prepare with confidence.",
            position: 1
          },
          %{
            title: "Calm Support During Delivery",
            body:
              "When labour begins, calm communication matters. Mothers and their families want to know what is happening, what to expect next, and when the team is concerned. Clear explanations reduce fear and help the patient stay engaged in the process.\n\nThe feedback we value most often mentions professionalism paired with kindness: staff who respond quickly, explain what they are doing, and stay attentive when mothers are at their most vulnerable.",
            image_url:
              "https://images.unsplash.com/photo-1516574187841-cb9cc2ca948b?auto=format&fit=crop&w=1200&q=80",
            image_alt: "A mother bonding with her newborn after delivery",
            image_caption:
              "Supportive communication can change how a mother remembers her delivery experience.",
            position: 2
          },
          %{
            title: "Postnatal Follow-Up Still Matters",
            body:
              "The period after delivery deserves just as much attention as pregnancy itself. Recovery, breastfeeding, wound care, mental wellbeing, and newborn checks all benefit from close follow-up.\n\nMothers often tell us that knowing who to return to and what signs to watch for makes the first days at home less stressful. Good postnatal care helps families leave with a clearer sense of what safe recovery looks like.",
            position: 3
          }
        ]
      },
      %{
        slug: "patient-records-continuity",
        category: "Health Records",
        title: "How We Keep Your Health Records Accurate Across Visits",
        author_name: "GHCE Clinical Team",
        excerpt:
          "A look at the systems behind your patient record and why continuity of care matters more than most people realise.",
        intro:
          "Reliable patient records are one of the quiet foundations of safe care. They reduce repetition, support better clinical decisions, and make it easier for different teams to care for the same person over time.",
        hero_image_url:
          "https://images.unsplash.com/photo-1538108149393-fbbd81895907?auto=format&fit=crop&w=1400&q=80",
        hero_image_alt: "A clinician reviewing an accurate digital patient record at GHCE",
        published_at: ~U[2026-02-01 00:00:00Z],
        status: "published",
        sections: [
          %{
            title: "Continuity Matters",
            body:
              "When a patient returns to hospital, good care should continue from where the last visit ended. Accurate records make that possible by preserving the details clinicians need to make safe decisions.\n\nWithout continuity, patients repeat the same history, clinicians work with gaps, and follow-up becomes harder than it should be.",
            quote:
              "A strong patient record turns separate visits into one connected story of care.",
            position: 0
          },
          %{
            title: "Reducing Repetition and Delay",
            body:
              "Accessible records save time for both patients and staff. Allergies, previous diagnoses, medicines, and test results can be reviewed without restarting the entire conversation at every encounter.\n\nThat saves valuable clinic time and reduces the risk of missed information, especially for patients managing chronic conditions.",
            position: 1
          },
          %{
            title: "Supporting Better Clinical Decisions",
            body:
              "A clinician makes better decisions when they can see the wider picture. Trends in blood pressure, recurring symptoms, earlier treatment plans, and past outcomes all help shape what should happen next.\n\nThat broader view is especially important when a patient is seen by more than one provider across outpatient care, pharmacy, laboratory, or maternal health services.",
            image_url:
              "https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=1200&q=80",
            image_alt: "A clinician reviewing a digital patient record during care planning",
            image_caption: "Good records help clinicians make safer decisions with more context.",
            position: 2
          },
          %{
            title: "Why Patients Benefit Too",
            body:
              "Patients may never see the full record workflow, but they feel its impact. Visits become smoother, follow-up is clearer, and treatment plans are easier to explain when the right information is already available.\n\nContinuity does not only protect the hospital. It protects the patient experience from becoming fragmented.",
            position: 3
          }
        ]
      }
    ]
  end
end
