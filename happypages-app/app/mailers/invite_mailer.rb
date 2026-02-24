class InviteMailer < ApplicationMailer
  def invite_email(user)
    @user = user
    @shop = user.shop
    @invite_url = invite_url(token: user.invite_token)

    mail(to: user.email, subject: "You're invited to Happypages")
  end
end
