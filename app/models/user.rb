class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable#, :harvard_auth_proxy_authenticatable        

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :repository_ids, :username
  
  validates_uniqueness_of :username
  
  has_and_belongs_to_many :courses, :order => "timeframe DESC, created_at DESC"
  has_and_belongs_to_many :repositories, :order => "name"
  has_many :notes
  
  def to_s
    self.full_name
  end
  
  def full_name
    return "#{self.first_name} #{self.last_name}"
  end
  
  def self.all_admins
    self.find(:all, :conditions => ["admin = true or superadmin = true"])
  end  
  
  def user_type
    if self.superadmin == true
      return "superadmin"
    elsif self.admin == true
      return "admin"
    elsif self.staff == true
      return "staff"
    elsif self.patron == true
      return "patron"  
    else
      return "none"  
    end      
  end 
  
  def self.random_password(size = 11)
    chars = (('a'..'z').to_a + ('0'..'9').to_a) - %w(i o 0 1 l 0)
    (1..size).collect{|a| chars[rand(chars.size)] }.join
  end
  
  def upcoming_courses
    upcoming = Array.new
    self.courses.collect{|course| course.status == "Scheduled, Claimed" ? upcoming << course : ''}
    upcoming << Course.all(:conditions => {:primary_contact_id => self.id, :status => "Scheduled, Claimed"})
    return upcoming.flatten
  end
  
  def past_courses
    past = Array.new
    self.courses.collect{|course| course.status == "Closed" ? past << course : ''}
    past << Course.all(:conditions => {:primary_contact_id => self.id, :status => "Closed"})
    
    return past.flatten
  end  
  
  def unscheduled_courses
    unscheduled = Array.new 
    self.courses.collect{|course| course.status == "Claimed, Unscheduled" ? unscheduled << course : ''}
    unscheduled << Course.all(:conditions => {:primary_contact_id => self.id, :status => "Claimed, Unscheduled"})
    return unscheduled.flatten.sort_by { |hsh| hsh[:created_at] }
  end
  
  def mine_current
    upcoming = Array.new
    upcoming = Course.find(:all, :conditions => ["contact_email = ? and (timeframe is NULL or timeframe >= ?)", self.email, DateTime.now], :order => 'timeframe DESC, created_at DESC')
    return upcoming
  end
  
  def mine_past
    past = Array.new
    past = Course.find(:all, :conditions => ["contact_email = ? and timeframe is not NULL and timeframe < ?", self.email, DateTime.now], :order => 'timeframe DESC, created_at DESC')
    return past
  end
  
  def upcoming_repo_courses
    upcoming_repo = Array.new
    all_courses = Array.new
    self.repositories.collect{|repo| all_courses << repo.courses}
    all_courses.flatten.collect{|course| !course.timeframe.nil? && course.timeframe >= DateTime.now ? upcoming_repo << course : ''}
    return upcoming_repo.sort_by { |hsh| hsh[:timeframe] }
  end
  
  def classes_to_close
    p "IN HERE"
    to_close = Array.new
    self.courses.collect{|course| !course.timeframe.nil? && course.timeframe < DateTime.now && course.status != "Closed" ? to_close << course : ''}
    to_close << Course.all(:conditions => ["timeframe is not null and timeframe < ? and status != 'Closed' and primary_contact_id = ?", DateTime.now, self.id])
    return to_close.flatten.sort_by { |hsh| hsh[:timeframe] }
  end

end
