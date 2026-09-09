defmodule MedcampWeb.ErrorHTMLTest do
  use MedcampWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    html = render_to_string(MedcampWeb.ErrorHTML, "404", "html", [])
    assert html =~ ">404<"
    assert html =~ "Page not found"
    assert html =~ "Tibasasa"
    assert html =~ "/images/tibasasa-ai-logo.png"
    refute html =~ "cdn.tailwindcss.com"
  end

  test "renders 500.html" do
    html = render_to_string(MedcampWeb.ErrorHTML, "500", "html", [])
    assert html =~ ">500<"
    assert html =~ "Something went wrong on our end"
    assert html =~ "Tibasasa"
    refute html =~ "cdn.tailwindcss.com"
  end

  test "renders 503.html" do
    html = render_to_string(MedcampWeb.ErrorHTML, "503", "html", [])
    assert html =~ ">503<"
    assert html =~ "Back shortly"
  end
end
