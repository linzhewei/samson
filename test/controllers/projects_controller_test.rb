require_relative '../test_helper'

describe ProjectsController do
  let(:project) { projects(:test) }

  setup do
    Project.any_instance.stubs(:clone_repository).returns(true)
    Project.any_instance.stubs(:valid_repository_url).returns(true)
  end

  describe "a GET to #index" do
    as_a_viewer do
      it "renders" do
        get :index
        assert_template :index
      end
    end

    as_a_deployer do
      it "renders" do
        get :index
        assert_template :index
      end
    end

    as_a_admin do
      it "renders" do
        get :index
        assert_template :index
      end

      it "assigns the user's starred projects to @projects" do
        starred_project = Project.create!(name: "a", repository_url: "a")
        users(:admin).stars.create!(project: starred_project)

        get :index

        assert_equal [starred_project], assigns(:projects)
      end

      it "assigns all projects to @projects if the user has no starred projects" do
        get :index

        assert_equal [projects(:test)], assigns(:projects)
      end
    end
  end

  describe "a GET to #new" do
    as_a_viewer do
      unauthorized :get, :new
    end

    as_a_deployer do
      unauthorized :get, :new
    end

    as_a_admin do
      it "renders" do
        get :new
        assert_template :new
      end
    end
  end

  describe "a POST to #create" do
    as_a_viewer do
      unauthorized :post, :create
    end

    as_a_deployer do
      unauthorized :post, :create
    end

    as_a_admin do
      setup do
        post :create, params
      end

      describe "with valid parameters" do
        let(:params) { { project: { name: "Hello", repository_url: "git://foo.com/bar" } } }
        let(:project) { Project.where(name: "Hello").first }

        it "redirects to the new project's page" do
          assert_redirected_to project_path(project)
        end

        it "creates a new project" do
          project.wont_be_nil
        end

        it "notifies about creation" do
          mail = ActionMailer::Base.deliveries.last
          mail.subject.include?("Samson Project Created")
          mail.subject.include?(project.name)
        end
      end

      describe "with invalid parameters" do
        let(:params) { { project: { name: "" } } }

        it "sets the flash error" do
          request.flash[:error].wont_be_nil
        end

        it "renders new template" do
          assert_template :new
        end
      end
    end
  end

  describe "a DELETE to #destroy" do
    as_a_viewer do
      unauthorized :delete, :destroy, id: 1
    end

    as_a_deployer do
      unauthorized :delete, :destroy, id: 1
    end

    as_a_admin do
      setup do
        delete :destroy, id: project.to_param
      end

      it "redirects to root url" do
        assert_redirected_to admin_projects_path
      end

      it "removes the project" do
        project.reload
        project.deleted_at.wont_be_nil
      end

      it "sets the flash" do
        request.flash[:notice].wont_be_nil
      end
    end
  end

  describe "a PUT to #update" do
    as_a_viewer do
      unauthorized :put, :update, id: 1
    end

    as_a_deployer do
      unauthorized :put, :update, id: 1
    end

    as_a_admin do
      it "does not find soft deleted" do
        project.soft_delete!
        put :update, id: project.to_param
        assert_redirected_to "/"
      end

      describe "common" do
        setup do
          put :update, params.merge(id: project.to_param)
        end

        describe "with valid parameters" do
          let(:params) { { project: { name: "Hi-yo" } } }

          it "redirects to root url" do
            assert_redirected_to project_path(project.reload)
          end

          it "creates a new project" do
            Project.where(name: "Hi-yo").first.wont_be_nil
          end
        end

        describe "with invalid parameters" do
          let(:params) { { project: { name: "" } } }

          it "sets the flash error" do
            request.flash[:error].wont_be_nil
          end

          it "renders edit template" do
            assert_template :edit
          end
        end
      end
    end
  end

  describe "a GET to #edit" do
    as_a_viewer do
      unauthorized :get, :edit, id: 1
    end

    as_a_deployer do
      unauthorized :get, :edit, id: 1
    end

    as_a_admin do
      it "renders" do
        get :edit, id: project.to_param
        assert_template :edit
      end

      it "does not find soft deleted" do
        project.soft_delete!
        get :edit, id: project.to_param
        assert_redirected_to "/"
      end
    end
  end

  describe "a GET to #show" do
    as_a_viewer do
      it "redirects to the deploys page" do
        get :show, id: project.to_param
        assert_redirected_to project_deploys_path(project)
      end
    end

    as_a_deployer do
      it "renders" do
        get :show, id: project.to_param
        assert_template :show
      end

      it "does not find soft deleted" do
        project.soft_delete!
        get :show, id: project.to_param
        assert_redirected_to "/"
      end
    end
  end
end
