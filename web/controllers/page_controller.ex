defmodule BadMammaJamma.PageController do
  use BadMammaJamma.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
