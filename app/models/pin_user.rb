class PinUser < User
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :harvard_auth_proxy_authenticatable
end
