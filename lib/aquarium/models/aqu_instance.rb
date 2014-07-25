class AquInstance < ActiveRecord::Base
  self.primary_key = 'instance_id'

  belongs_to :aqu_database, :foreign_key => "database_id"

  validates :name, :presence=>true, :length => { :maximum => 100 },
            :uniqueness => {:scope => "database_id",:case_sensitive =>false, :message => "- must be unique"}
  validates :url, :presence=>true, :length => { :maximum => 200 }
  validates :username, :presence=>true, :length => { :maximum => 100 }
  validates :salt, :presence=>true, :length => { :maximum => 16 }
  validates :password, :presence=>true, :length => { :maximum => 100 }
  validates :production, :presence=>true, :length => { :maximum => 100 },:inclusion => {:in =>[0,1]}

  before_save :set_update_sysdate
  before_create :set_create_sysdate

  # Set create and update dates automatically
  def set_update_sysdate
    self.update_sysdate = DateTime.now()
  end
  def set_create_sysdate
    self.create_sysdate = DateTime.now()
  end

  # Accessors for encrypted password
  def password=(password)
    return if password.blank?

    # Regenerate salt each time password is changed
    salt = 16.times.map{Random.rand(10)}.join
    write_attribute(:salt,salt)

    secret_key = Digest::MD5.digest(ActiveRecord::Base.configurations[Rails.env]["secret"]||"m0nitr$this")
    iv = Digest::MD5.digest(salt)
    write_attribute(:password, Base64.encode64(Encryptor.encrypt(password, :key => secret_key,:iv=>iv)))
  end

  def password
    secret_key = Digest::MD5.digest(ActiveRecord::Base.configurations[Rails.env]["secret"]||"m0nitr$this")
    iv = Digest::MD5.digest(read_attribute(:salt))
    Encryptor.decrypt(Base64.decode64(read_attribute(:password)), :key => secret_key,:iv=>iv)
  end

  # This can be used to re-encrypt passwords
  def password_with(secret,salt)
    secret_key = Digest::MD5.digest(secret)
    iv = Digest::MD5.digest(salt)
    Encryptor.decrypt(Base64.decode64(read_attribute(:password)), :key => secret_key,:iv=>iv)
  end
end
