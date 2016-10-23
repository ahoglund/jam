defmodule BadMammaJamma.JamControllerTest do
  use BadMammaJamma.ConnCase

  alias BadMammaJamma.Jam
  @valid_attrs %{}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, jam_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing jams"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, jam_path(conn, :new)
    assert html_response(conn, 200) =~ "New jam"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, jam_path(conn, :create), jam: @valid_attrs
    assert redirected_to(conn) == jam_path(conn, :index)
    assert Repo.get_by(Jam, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, jam_path(conn, :create), jam: @invalid_attrs
    assert html_response(conn, 200) =~ "New jam"
  end

  test "shows chosen resource", %{conn: conn} do
    jam = Repo.insert! %Jam{}
    conn = get conn, jam_path(conn, :show, jam)
    assert html_response(conn, 200) =~ "Show jam"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, jam_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    jam = Repo.insert! %Jam{}
    conn = get conn, jam_path(conn, :edit, jam)
    assert html_response(conn, 200) =~ "Edit jam"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    jam = Repo.insert! %Jam{}
    conn = put conn, jam_path(conn, :update, jam), jam: @valid_attrs
    assert redirected_to(conn) == jam_path(conn, :show, jam)
    assert Repo.get_by(Jam, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    jam = Repo.insert! %Jam{}
    conn = put conn, jam_path(conn, :update, jam), jam: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit jam"
  end

  test "deletes chosen resource", %{conn: conn} do
    jam = Repo.insert! %Jam{}
    conn = delete conn, jam_path(conn, :delete, jam)
    assert redirected_to(conn) == jam_path(conn, :index)
    refute Repo.get(Jam, jam.id)
  end
end
