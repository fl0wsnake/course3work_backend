defmodule Course3.Guardian do
  use Guardian, otp_app: :course3
  alias Course3.Repo
  alias Course3.User

  def subject_for_token(resource, _claims) do
    {:ok, resource.id}
  end

  def resource_from_claims(claims) do
    {:ok, Repo.get!(User, claims["sub"])}
  end
end
