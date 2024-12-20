defmodule RealDealApiWeb.AccountController do
  use RealDealApiWeb, :controller

  alias RealDealApiWeb.{Auth.Guardian, Auth.ErrorResponse}
  alias RealDealApi.{Accounts, Accounts.Account, Users, Users.User}

  action_fallback RealDealApiWeb.FallbackController

  def index(conn, _params) do
    accounts = Accounts.list_accounts()
    render(conn, :index, accounts: accounts)
  end

  def create(conn, %{"account" => account_params}) do
    with {:ok, %Account{} = account} <- Accounts.create_account(account_params),
    {:ok, token, _claims} <- Guardian.encode_and_sign(account),
    {:ok, %User{} = _user} <- Users.create_user(account, account_params) do
      conn
      |> put_status(:created)
      # Phoenix 1.7 introduced a new JSON-only rendering convention with *_JSON modules for APIs
      #  Pay attention to ensures that Phoenix uses RealDealApiWeb.AccountView instead of looking for RealDealApiWeb.AccountJSON.
      |> put_view(RealDealApiWeb.AccountView)  # Explicitly set the view module
      |> render(:show, account: account)
    end
  end

  def sign_in(conn, %{"email" => email, "hash_password" => hash_password}) do
    case Guardian.authenticate(email, hash_password) do
      {:ok, account, token} ->
        conn
        |> put_status(:ok)
        |> put_view(RealDealApiWeb.AccountView)
        |> render(:account_with_token, %{account: account, token: token})
      {:error, :unauthorized} -> raise ErrorResponse.Unauthorized, message: "Email or Password incorrect."
    end
  end

  def show(conn, %{"id" => id}) do
    account = Accounts.get_account!(id)
    render(conn, :show, account: account)
  end

  def update(conn, %{"id" => id, "account" => account_params}) do
    account = Accounts.get_account!(id)

    with {:ok, %Account{} = account} <- Accounts.update_account(account, account_params) do
      render(conn, :show, account: account)
    end
  end

  def delete(conn, %{"id" => id}) do
    account = Accounts.get_account!(id)

    with {:ok, %Account{}} <- Accounts.delete_account(account) do
      send_resp(conn, :no_content, "")
    end
  end
end
