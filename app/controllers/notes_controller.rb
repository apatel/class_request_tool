class NotesController < ApplicationController
  before_filter :authenticate_admin_or_staff!, :only => [:destroy, :update]
  
  def index
    @notes = Note.find(:all, :order => :created_at)
  end  
  
  def new
    @note = Note.new
  end
  
  def edit
    @note = Note.find(params[:id])
    @course = @note.course
    unless current_user.try(:staff?) || current_user.try(:admin?) || current_user.try(:superadmin?) || @note.course.contact_email == current_user.email
       redirect_to('/') and return
    end
  end
  
  def create
    @note = Note.new(params[:note])
    respond_to do |format|
      if @note.save
        @note.new_note_email(current_user)
        unless @note.staff_comment || @note.course.contact_email == current_user.email
          @note.new_patron_note_email
        end
        format.html { redirect_to course_url(@note.course), notice: 'Note was successfully created.' }
        format.json { render json: @note, status: :created, note: @note }
      else
        format.html { render action: "new" }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update
    @note = Note.find(params[:id])
    unless current_user.try(:staff?) || current_user.try(:admin?) || current_user.try(:superadmin?) || @note.course.contact_email == current_user.email
       redirect_to('/') and return
    end

    respond_to do |format|
      if @note.update_attributes(params[:note])
        format.html { redirect_to course_url(@note.course), notice: 'Note was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @note = Note.find(params[:id])
    @course = @note.course
    unless current_user.try(:staff?) || current_user.try(:admin?) || current_user.try(:superadmin?) || @course.contact_email == current_user.email
       redirect_to('/') and return
    end
    @note.destroy

    respond_to do |format|
      format.html { redirect_to course_url(@course) }
      format.json { head :no_content }
    end
  end
end
