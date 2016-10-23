defmodule BadMammaJamma.JamController do
  use BadMammaJamma.Web, :controller

  alias BadMammaJamma.Jam

  plug :scrub_params, "jam" when action in [:create, :update]

  def index(conn, _params) do
    jams = Repo.all(Jam)
    changeset = Jam.changeset(%Jam{})
    render(conn, "index.html", jams: jams, changeset: changeset)
  end

  def create(conn, %{"jam" => jam_params}) do
    changeset = Jam.changeset(%Jam{}, jam_params)

    case Repo.insert(changeset) do
      {:ok, jam} ->
        conn
        |> put_flash(:info, "Jam created successfully.")
        |> redirect(to: jam_path(conn, :show, jam))
      {:error, changeset} ->
        render(conn, "index.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    jam = Repo.get!(Jam, id)
    render(conn, "show.html", jam: jam)
  end

  def edit(conn, %{"id" => id}) do
    jam = Repo.get!(Jam, id)
    changeset = Jam.changeset(jam)
    render(conn, "edit.html", jam: jam, changeset: changeset)
  end

  def update(conn, %{"id" => id, "jam" => jam_params}) do
    jam = Repo.get!(Jam, id)
    changeset = Jam.changeset(jam, jam_params)

    case Repo.update(changeset) do
      {:ok, jam} ->
        conn
        |> put_flash(:info, "Jam updated successfully.")
        |> redirect(to: jam_path(conn, :show, jam))
      {:error, changeset} ->
        render(conn, "edit.html", jam: jam, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    jam = Repo.get!(Jam, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(jam)

    conn
    |> put_flash(:info, "Jam deleted successfully.")
    |> redirect(to: jam_path(conn, :index))
  end
end
