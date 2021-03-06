defmodule Course3.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Course3.Repo, []),
      supervisor(Course3Web.Endpoint, []),
    ]

    opts = [strategy: :one_for_one, name: Course3.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Course3Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
