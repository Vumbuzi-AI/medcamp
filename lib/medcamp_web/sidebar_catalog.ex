defmodule MedcampWeb.SidebarCatalog do
  @moduledoc """
  The single source of truth for what panels each role has: the sidebar
  tab groups per role, plus the permission slug and URL prefixes each tab
  maps to.

  Both halves of access control read from here:

    * `MedcampWeb.SidebarComponents` renders only the tabs the current user
      can see (`visible_tab_groups/1`).
    * `MedcampWeb.Plugs.RequirePanelPermission` blocks the routes behind a
      tab the user cannot see, so hiding a link in the sidebar also closes
      the URL.

  A tab's permission slug is derived from its role and `tab_name`
  (`"doctor.patients"`, `"admin.audit_logs"`, ...), so adding a tab here
  plus a migration calling `Medcamp.Authorization.PanelSync.sync/1` is all
  it takes to make a new panel grantable.
  """

  alias Medcamp.Authorization

  @roles [
    "admin",
    "doctor",
    "nurse",
    "labtechnician",
    "pharmacist"
  ]

  # No camp role borrows another's sidebar; each of the five works only its
  # own pages. Kept as an empty map so the sharing machinery below stays
  # intact if that ever changes again.
  @shared_panel_roles %{}

  @doc """
  The other roles' sidebars `role` is given in full, in addition to its
  own (`"reception"` -> `["inventory_manager"]`).
  """
  def shared_panel_roles(role), do: Map.get(@shared_panel_roles, role, [])

  @doc """
  The tabs of every sidebar shared with `role`, flattened and annotated
  the way `all_tabs/1` does - keeping each tab's *owning* role's slug,
  since that is what the shared sidebar renders and the router checks.
  Group names carry the owning role so the admin permissions page does
  not show two unrelated "Stock Management" groups.
  """
  def shared_tabs(role) do
    role
    |> shared_panel_roles()
    |> Enum.flat_map(fn shared_role ->
      Enum.map(all_tabs(shared_role), fn tab ->
        %{tab | group_name: "#{tab.group_name} (#{role_label(shared_role)})"}
      end)
    end)
  end

  defp role_label("labtechnician"), do: "Lab Technician"
  defp role_label(role), do: String.capitalize(role)

  @doc """
  Roles that have a permission-controlled sidebar.
  """
  def roles, do: @roles

  @doc """
  The full, unfiltered tab groups for `role` - every panel the role could
  possibly be given. This is what the admin permissions page lists.
  """
  def tab_groups("admin"), do: admin_tab_groups()
  def tab_groups("doctor"), do: doctor_tab_groups()
  def tab_groups("nurse"), do: nurse_tab_groups()
  def tab_groups("labtechnician"), do: lab_tab_groups()
  def tab_groups("pharmacist"), do: pharmacist_tab_groups()
  def tab_groups(_role), do: []

  @doc """
  The permission slug for a tab belonging to `role`, e.g.
  `permission_slug("doctor", :lab_results)` -> `"doctor.lab_results"`.

  The role segment is normalised to match the slug style already in use
  (`labtechnician` -> `lab`).
  """
  def permission_slug(role, tab_name) do
    "#{slug_role(role)}.#{tab_name}"
  end

  defp slug_role("labtechnician"), do: "lab"
  defp slug_role(role) when is_binary(role), do: role

  @doc """
  Every tab in the system for `role`, flattened, each annotated with the
  permission slug that controls it and the group it belongs to. Used to
  seed permissions and to render the admin permissions page.
  """
  def all_tabs(role) do
    role
    |> tab_groups()
    |> Enum.flat_map(fn group ->
      Enum.map(group.tabs, fn tab ->
        %{
          role: role,
          group_key: group.key,
          group_name: group.name,
          name: tab.name,
          icon: tab.icon,
          url: tab.url,
          tab_name: tab.tab_name,
          slug: permission_slug(role, tab.tab_name)
        }
      end)
    end)
  end

  @doc """
  Every panel permission slug in the system, across all roles, as
  `%{slug: ..., description: ..., resource_area: ...}` maps ready to
  insert into `permissions`. Slugs are shared between roles where the
  same panel appears in both (e.g. `duty_rota`), so this is deduplicated.
  """
  def all_permissions do
    main =
      roles()
      |> Enum.flat_map(&all_tabs/1)
      |> Enum.map(fn tab ->
        %{
          slug: tab.slug,
          description: "#{tab.name} panel",
          resource_area: tab.group_key
        }
      end)

    per_patient =
      roles()
      |> Enum.flat_map(&all_patient_tabs/1)
      |> Enum.map(fn tab ->
        %{
          slug: tab.slug,
          description: "#{tab.name} (patient record)",
          resource_area: "patient_record"
        }
      end)

    Enum.uniq_by(main ++ per_patient, & &1.slug)
  end

  @doc """
  The tab groups of the `panel_role` sidebar, with every panel `user` does
  not have permission for removed and any group left with no tabs dropped.

  `panel_role` is the sidebar being rendered rather than `user.role`,
  because a few sidebars are shared - an admin or receptionist visiting
  the inventory manager's pages sees the inventory manager sidebar, and
  so is checked against the `inventory_manager.*` slugs that sidebar's
  tabs are guarded by.

  Resolves the whole set in one query rather than calling
  `Authorization.can?/2` per tab.
  """
  def visible_tab_groups(user, panel_role \\ nil)

  def visible_tab_groups(nil, _panel_role), do: []

  def visible_tab_groups(%{role: role} = user, panel_role) do
    panel_role = panel_role || role
    allowed = Authorization.effective_permissions(user)

    panel_role
    |> tab_groups()
    |> Enum.map(fn group ->
      tabs =
        Enum.filter(
          group.tabs,
          &MapSet.member?(allowed, permission_slug(panel_role, &1.tab_name))
        )

      %{group | tabs: tabs}
    end)
    |> Enum.reject(&(&1.tabs == []))
  end

  @doc """
  The tabs of the per-patient sidebar for `role` - the sections shown
  once a user has opened a specific patient (overview, notes, triages,
  lab results, ...), filtered to the ones `user` has permission for.

  These are panels in their own right, slugged `<role>.patient.<tab>`
  to keep them distinct from the main sidebar's `<role>.<tab>`: a
  doctor can hold the all-patients "Lab Results" panel
  (`doctor.lab_results`) without holding the per-patient one
  (`doctor.patient.lab_results`), and vice versa.

  The "back to the list" tab that every one of these sidebars opens
  with is never filtered out - removing it would strand the user on a
  patient page with no way back.
  """
  def visible_patient_tabs(user, role, patient)

  def visible_patient_tabs(nil, _role, _patient), do: []

  def visible_patient_tabs(user, role, patient) do
    allowed = Authorization.effective_permissions(user)
    [back | rest] = patient_tabs(role, patient)

    visible =
      Enum.filter(rest, fn tab ->
        case patient_tab_slug(role, tab, patient) do
          nil -> true
          slug -> MapSet.member?(allowed, slug)
        end
      end)

    [back | visible]
  end

  # A per-patient sidebar mixes two kinds of tab: sections of the open
  # patient's record (`/doctor/42/forms`), and plain links back out to
  # shared pages the main sidebar also lists (`/requisitions`). Only the
  # former are patient-record panels; the latter reuse whatever slug the
  # main sidebar already gates them by, so revoking "Requisitions" once
  # revokes it in both places rather than needing two ticks.
  defp patient_tab_slug(role, tab, patient) do
    if patient_scoped?(tab.url, patient) do
      patient_permission_slug(role, tab.tab_name)
    else
      main_slug_for_url(role, tab.url)
    end
  end

  defp patient_scoped?(url, patient) do
    String.contains?(url, "/#{patient.id}/") or String.ends_with?(url, "/#{patient.id}")
  end

  # `nil` when the main sidebar has no tab at this URL either - the link
  # is not a panel anyone can grant, so it stays visible.
  defp main_slug_for_url(role, url) do
    role
    |> all_tabs()
    |> Enum.find_value(fn tab -> if tab.url == url, do: tab.slug end)
  end

  @doc """
  The permission slug for a per-patient tab, e.g.
  `patient_permission_slug("doctor", :mch)` -> `"doctor.patient.mch"`.
  """
  def patient_permission_slug(role, tab_name) do
    "#{slug_role(role)}.patient.#{tab_name}"
  end

  @doc """
  Every per-patient tab for `role`, annotated with its permission slug.
  Rendered with a placeholder patient, since the slugs depend only on
  `tab_name` and not on which patient is open.
  """
  def all_patient_tabs(role) do
    case patient_tabs(role, placeholder_patient()) do
      [] ->
        []

      [_back | rest] ->
        rest
        |> Enum.filter(&patient_scoped?(&1.url, placeholder_patient()))
        |> Enum.map(fn tab ->
          %{
            role: role,
            name: tab.name,
            icon: tab.icon,
            url: tab.url,
            tab_name: tab.tab_name,
            slug: patient_permission_slug(role, tab.tab_name)
          }
        end)
    end
  end

  # Patient tabs are built against a real patient struct; this stands in
  # when we only want the shape of the URLs, not a specific record.
  defp placeholder_patient, do: %{id: 0}

  defp patient_tabs("doctor", patient), do: doctor_patient_tabs(patient)
  defp patient_tabs("nurse", patient), do: nurse_patient_tabs(patient)
  defp patient_tabs("pharmacist", patient), do: pharmacist_patient_tabs(patient)
  defp patient_tabs("labtechnician", patient), do: lab_patient_tabs(patient)
  defp patient_tabs(_role, _patient), do: []

  @doc """
  The panel a path belongs to, derived from its URL prefix
  (`/inventory_manager/in_store` -> `"inventory_manager"`), or `nil` for
  paths outside any role's prefix.

  Route enforcement keys off this rather than `user.role` so that shared
  pages resolve to the slug their sidebar actually renders: an admin
  opening `/inventory_manager/in_store` is checked against
  `inventory_manager.in_store`, the same slug their sidebar link is
  hidden by.
  """
  def panel_role_for_path("/admin/" <> _), do: "admin"
  def panel_role_for_path("/doctor/" <> _), do: "doctor"
  def panel_role_for_path("/nurse/" <> _), do: "nurse"
  def panel_role_for_path("/lab/" <> _), do: "labtechnician"
  def panel_role_for_path("/pharmacist/" <> _), do: "pharmacist"
  def panel_role_for_path(_path), do: nil

  @doc """
  The permission slug guarding `path` for `role`, or `nil` if no panel in
  that role's sidebar claims it.

  Per-patient sections are checked first and win, because they are the
  more specific claim: `/doctor/patients/42/notes` is guarded by
  `doctor.patient.doctor_notes`, not by the all-patients
  `doctor.patients` tab it happens to sit under. A user who has the
  patient list but not the notes section can open the patient and still
  be kept out of the notes.

  Failing that, matches the longest main-sidebar tab URL that `path`
  starts with, so `/doctor/patient_visits` resolves to its own tab
  rather than being swallowed by `/doctor/patients`.
  """
  def permission_for_path(role, path) do
    patient_permission_for_path(role, path) || main_permission_for_path(role, path)
  end

  @doc """
  Every panel slug that can grant `path`, given the user's own `role`.

  A path is usually claimed only by the sidebar whose prefix it sits
  under, but some panels are cross-linked: a receptionist's Inventories
  group points at `/inventory_manager/inventories_received`, which they
  reach with `reception.medical_inventory` rather than the
  `inventory_manager.*` slug the URL prefix implies. Holding *either*
  claim is enough, so route enforcement checks the union instead of the
  panel-role slug alone - otherwise a visible sidebar link leads to a
  permission error.
  """
  def permissions_for_path(role, path) do
    [panel_role_for_path(path), role]
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.map(&permission_for_path(&1, path))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp main_permission_for_path(role, path) do
    role
    |> all_tabs()
    |> Enum.filter(&path_matches?(path, &1.url))
    |> Enum.max_by(&String.length(&1.url), fn -> nil end)
    |> case do
      nil -> nil
      tab -> tab.slug
    end
  end

  # Per-patient tab URLs embed the open patient's id, and not always in
  # the same position (`/doctor/patients/42/notes` but
  # `/doctor/42/forms`), so they are matched segment-by-segment with the
  # id position treated as a wildcard rather than by string prefix.
  defp patient_permission_for_path(role, path) do
    segments = split_path(path)

    role
    |> all_patient_tabs()
    |> Enum.filter(&patient_path_matches?(segments, &1.url))
    |> Enum.max_by(&length(split_path(&1.url)), fn -> nil end)
    |> case do
      nil -> nil
      tab -> tab.slug
    end
  end

  # `all_patient_tabs/1` builds its URLs with a placeholder patient id of
  # 0; that segment matches whichever id is actually in the path. Trailing
  # segments are allowed so a tab covers its own sub-pages
  # (`.../notes/new` belongs to the notes section).
  #
  # The id position only matches a number, so list-management routes that
  # sit where an id would go - `/doctor/patients/new` - fall through to
  # the main sidebar's `doctor.patients` instead of being mistaken for a
  # patient record.
  defp patient_path_matches?(segments, tab_url) do
    tab_segments = split_path(tab_url)

    length(segments) >= length(tab_segments) and
      segments
      |> Enum.zip(tab_segments)
      |> Enum.all?(fn
        {segment, "0"} -> numeric?(segment)
        {segment, tab_segment} -> segment == tab_segment
      end)
  end

  defp numeric?(segment), do: match?({_, ""}, Integer.parse(segment))

  defp split_path(path) do
    path |> String.split("/", trim: true)
  end

  defp path_matches?(path, url) do
    path == url or String.starts_with?(path, url <> "/")
  end

  defp doctor_tab_groups do
    [
      %{
        key: "patient-management",
        name: "Patient Management",
        icon: "users",
        tabs: [
          %{
            name: "Scan Patient",
            icon: "magnifying-glass-circle",
            url: "/doctor/scan",
            tab_name: :scan
          },
          %{name: "Patient List", icon: "users", url: "/doctor/patients", tab_name: :patients},
          %{
            name: "My Visits",
            icon: "home-modern",
            url: "/doctor/patient_visits",
            tab_name: :visits
          },
          %{
            name: "Pending Cases",
            icon: "calculator",
            url: "/doctor/pending_patient_visits",
            tab_name: :pending
          }
        ]
      },
      %{
        key: "clinical-work",
        name: "Clinical Work",
        icon: "document-text",
        tabs: [
          %{
            name: "Lab Results",
            icon: "document",
            url: "/doctor/lab_results",
            tab_name: :lab_results
          }
        ]
      }
    ]
  end

  defp admin_tab_groups do
    [
      %{
        key: "camp",
        name: "Medical Camp",
        icon: "heart",
        tabs: [
          %{
            name: "Camp Overview",
            icon: "heart",
            url: "/admin/medical_camp",
            tab_name: :medical_camp
          }
        ]
      },
      %{
        key: "patient-care",
        name: "Patient Care",
        icon: "user-group",
        tabs: [
          %{name: "Patients", icon: "users", url: "/admin/patients", tab_name: :patients},
          %{
            name: "Patient Visits",
            icon: "home-modern",
            url: "/admin/patient_visits",
            tab_name: :visits
          },
          %{
            name: "Doctor Note Quality",
            icon: "chart-bar-square",
            url: "/admin/doctor-note-quality",
            tab_name: :doctor_note_quality
          },
          %{
            name: "Doctor Note Search",
            icon: "document-magnifying-glass",
            url: "/admin/doctor-note-search",
            tab_name: :doctor_note_search
          }
        ]
      },
      %{
        key: "pharmacy",
        name: "Pharmacy",
        icon: "beaker",
        tabs: [
          %{name: "Drugs", icon: "beaker", url: "/admin/drugs", tab_name: :admin_drugs},
          %{
            name: "Drug Allocations",
            icon: "chart-bar",
            url: "/admin/drug_allocations",
            tab_name: :drug_allocation_report
          },
          %{
            name: "Consumption Analysis",
            icon: "chart-bar",
            url: "/admin/consumption_analysis",
            tab_name: :consumption_analysis
          }
        ]
      },
      %{
        key: "laboratory",
        name: "Laboratory",
        icon: "document-magnifying-glass",
        tabs: [
          %{
            name: "Lab Tests",
            icon: "document-magnifying-glass",
            url: "/lab_tests",
            tab_name: :lab_tests
          },
          %{
            name: "Lab Surveillance",
            icon: "chart-bar-square",
            url: "/admin/lab_surveillance",
            tab_name: :lab_surveillance
          }
        ]
      },
      %{
        key: "admin-operations",
        name: "Admin Operations",
        icon: "cog-6-tooth",
        tabs: [
          %{name: "System Users", icon: "users", url: "/admin/users", tab_name: :users},
          %{
            name: "Login Sessions",
            icon: "arrow-right-on-rectangle",
            url: "/admin/login_sessions",
            tab_name: :login_sessions
          },
          %{
            name: "Audit Logs",
            icon: "shield-check",
            url: "/admin/audit_logs",
            tab_name: :audit_logs
          }
        ]
      }
    ]
  end

  defp nurse_tab_groups do
    [
      %{
        key: "patient-management",
        name: "Patient Management",
        icon: "users",
        tabs: [
          %{
            name: "Scan Patient",
            icon: "magnifying-glass-circle",
            url: "/nurse/scan",
            tab_name: :scan
          },
          %{name: "Patients", icon: "users", url: "/nurse/patients", tab_name: :patients},
          %{name: "Triages", icon: "computer-desktop", url: "/nurse/triages", tab_name: :triages},
          %{name: "Visits", icon: "home-modern", url: "/nurse/visits", tab_name: :visits}
        ]
      }
    ]
  end

  defp pharmacist_tab_groups do
    [
      %{
        key: "drug-management",
        name: "Drug Management",
        icon: "beaker",
        tabs: [
          %{
            name: "Scan Patient",
            icon: "magnifying-glass-circle",
            url: "/pharmacist/scan",
            tab_name: :scan
          },
          %{name: "Drugs", icon: "folder-plus", url: "/pharmacist/drugs", tab_name: :drugs},
          %{
            name: "Drug Allocations",
            icon: "clock",
            url: "/pharmacist/drug_allocations",
            tab_name: :drug_allocations
          }
        ]
      },
      %{
        key: "analytics",
        name: "Analytics",
        icon: "chart-bar",
        tabs: [
          %{
            name: "Drug Allocation Report",
            icon: "chart-bar",
            url: "/pharmacist/drug_allocations/report",
            tab_name: :drug_allocation_report
          }
        ]
      }
    ]
  end

  defp lab_tab_groups do
    [
      %{
        key: "lab-work",
        name: "Lab Work",
        icon: "beaker",
        tabs: [
          %{name: "Scan Patient", icon: "qr-code", url: "/lab/scan", tab_name: :scan},
          %{name: "Lab Results", icon: "beaker", url: "/lab/lab_results", tab_name: :lab_results},
          %{
            name: "Lab Surveillance",
            icon: "chart-bar-square",
            url: "/lab/surveillance",
            tab_name: :lab_surveillance
          },
          %{name: "Lab Tests", icon: "beaker", url: "/lab/lab_tests", tab_name: :lab_tests},
          %{
            name: "Lab Test Templates",
            icon: "code-bracket-square",
            url: "/lab/lab_test_templates",
            tab_name: :lab_test_templates
          }
        ]
      }
    ]
  end

  defp nurse_patient_tabs(patient) do
    [
      %{
        name: "All Patients",
        icon: "backward",
        url: "/nurse/patients",
        tab_name: :patients
      },
      %{
        name: "Patient Overview",
        icon: "user",
        url: "/nurse/#{patient.id}/patient_overview",
        tab_name: :patient_overview
      },
      %{
        name: "Patient Triages",
        icon: "computer-desktop",
        url: "/nurse/#{patient.id}/triages",
        tab_name: :triages
      },
      %{
        name: "Patient Visits",
        icon: "home-modern",
        url: "/nurse/#{patient.id}/visits",
        tab_name: :visits
      },
      %{
        name: "Doctor's Notes",
        icon: "pencil-square",
        url: "/nurse/#{patient.id}/doctor_notes",
        tab_name: :doctor_notes
      }
    ]
  end

  defp pharmacist_patient_tabs(patient) do
    [
      %{
        name: "All Drugs",
        icon: "users",
        url: "/pharmacist/drugs",
        tab_name: :drugs
      },
      %{
        name: "Patient Drug Allocations",
        icon: "users",
        url: "/pharmacist/#{patient.id}/drug_allocations",
        tab_name: :drug_allocations
      }
    ]
  end

  defp lab_patient_tabs(patient) do
    [
      %{
        name: "All Lab Results",
        icon: "backward",
        url: "/lab/lab_results",
        tab_name: :all_lab_results
      },
      %{
        name: "Patient Lab Results",
        icon: "user",
        url: "/lab/#{patient.id}/lab_results",
        tab_name: :lab_results
      }
    ]
  end

  defp doctor_patient_tabs(patient) do
    [
      %{
        name: "All Patients",
        icon: "backward",
        url: "/doctor/patients",
        tab_name: :patients
      },
      %{
        name: "Patient Overview",
        icon: "user",
        url: "/doctor/patients/#{patient.id}",
        tab_name: :overview
      },
      %{
        name: "Doctor's Notes",
        icon: "pencil-square",
        url: "/doctor/patients/#{patient.id}/notes",
        tab_name: :doctor_notes
      },
      %{
        name: "Visits",
        icon: "home-modern",
        url: "/doctor/patients/#{patient.id}/visits",
        tab_name: :visits
      },
      %{
        name: "Triages",
        icon: "computer-desktop",
        url: "/doctor/patients/#{patient.id}/triages",
        tab_name: :triages
      },
      %{
        name: "Lab Results",
        icon: "clipboard-document-list",
        url: "/doctor/patients/#{patient.id}/lab_results",
        tab_name: :lab_results
      },
      %{
        name: "Drug Allocations",
        icon: "beaker",
        url: "/doctor/patients/#{patient.id}/drug_allocations",
        tab_name: :drug_allocations
      }
    ]
  end
end
