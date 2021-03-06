class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :duration_data, :slowest_tests, :unstable_tests, :chart]

  def index
    @projects = Project.all
    @projects = @projects.displayable unless params.fetch(:show_hidden, :false) == 'true'
  end

  def show
    @builds = @project.builds.order(number: :desc).page params[:page]
    raw_suites = @project.suites
    @suites = []
    raw_suites.each do |suite|
      @suites << SuitePresenter.new(suite)
    end
  end

  def chart
  end

  def duration_data
    ret_val = {}
    @project.builds.where.not(run_date: nil).order(number: :desc).map { |build| ret_val[build.run_date] = build.duration_in_seconds }

    render json: ret_val
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = Project.new(project_params)

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    DeleteProjectJob.perform_later(@project.id)

    respond_to do |format|
      format.html { redirect_to projects_url, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def slowest_tests
    @slowest_tests = Stats::SlowestTests.new(
        @project,
        params.fetch(:build_count, Stats::SlowestTests::DEFAULT_BUILD_COUNT),
        params.fetch(:test_count, Stats::SlowestTests::DEFAULT_TEST_COUNT)
    )
  end

  def unstable_tests
    @unstable_tests = Stats::UnstableTests.new(
        @project,
        params.fetch(:build_count, Stats::UnstableTests::DEFAULT_BUILD_COUNT),
        params.fetch(:test_count, Stats::UnstableTests::DEFAULT_TEST_COUNT)
    )
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :hide)
  end

end
