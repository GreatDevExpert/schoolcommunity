class ParentChildRelationshipsController < ApplicationController
  def create
    relationship = ParentChildRelationship.new(relationship_params)
    relationship.parent = current_user if relationship_params[:child_id]
    relationship.child = current_user if relationship_params[:parent_id]
    relationship.requesting_user = current_user

    if relationship.save
      redirect_to parent_child_relationships_path, notice: "Your request has been sent"
    else
      redirect_to parent_child_relationships_path, notice: relationship.errors.full_messages.first
    end
  end

  def index
    @parent_relationships = current_user.parent_relationships
    @child_relationships = current_user.child_relationships
  end

  def destroy
    @relationship = ParentChildRelationship.find(params[:id])
    if @relationship.destroy
      redirect_to parent_child_relationships_path, notice: "This relationship has been removed"
    else
      redirect_to parent_child_relationships_path, error: "Unable to remove relationship"
    end
  end

  def approve
    @relationship = ParentChildRelationship.find(params[:id])
    authorize @relationship

    if @relationship.approve!
      redirect_to parent_child_relationships_path, notice: "Your relationship has been approved"
    else
      redirect_to parent_child_relationships_path, error: "An error has occurred approving your relationship"
    end
  end
  
  private
  def relationship_params
    params.require(:parent_child_relationship).permit(:child_id, :parent_id)
  end
end
