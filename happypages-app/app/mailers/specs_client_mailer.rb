class SpecsClientMailer < ApplicationMailer
  def invite_email(specs_client)
    @client = specs_client
    @organisation = specs_client.organisation
    @invite_url = specs_invite_url(token: specs_client.invite_token)

    mail(to: specs_client.email, subject: "You're invited to #{@organisation.name} on Happypages Specs")
  end
end
