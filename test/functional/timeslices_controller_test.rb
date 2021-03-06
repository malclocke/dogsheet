require 'test_helper'

class TimeslicesControllerTest < ActionController::TestCase

  setup :activate_authlogic

  def test_block_logged_out_users
    get :index
    assert_redirected_to new_user_session_url
    get :show
    assert_redirected_to new_user_session_url
    get :new
    assert_redirected_to new_user_session_url
    get :create
    assert_redirected_to new_user_session_url
  end

  def test_should_get_index_logged_in
    UserSession.create(users(:one))
    get :index
    assert_response :success
  end

  def test_should_only_assign_active_users_timeslices
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14'
    assert_response :success
    assert_not_nil assigns(:timeslices)
    assert_equal 2, assigns(:timeslices).length, "only assigns timeslices for user one"
  end

  def test_should_not_assign_multiday_var
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14'
    assert_response :success
    assert_not_nil assigns(:multiday)
    assert_equal false, assigns(:multiday),
      "assigns multiday to false in single day view"
    assert_select "div#timesheet.singleday"
    assert_select "div#timesheet.multiday", false
    assert_select "div#timeslice-form-2009-11-14"
  end

  def test_should_not_assign_multiday_var_when_start_and_end_date_the_same
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14', :end_date => '2009-11-14'
    assert_response :success
    assert_not_nil assigns(:multiday)
    assert_equal false, assigns(:multiday),
      "assigns multiday to false in single day view"
    assert_select "div#timesheet.singleday"
    assert_select "div#timesheet.multiday", false
    assert_select "div#timeslice-form-2009-11-14"
  end

  def test_should_assign_multiday_var
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14', :end_date => '2009-11-15'
    assert_response :success
    assert_not_nil assigns(:multiday)
    assert_equal true, assigns(:multiday),
      "assigns multiday to true in multiple day view"
    assert_select "div#timesheet.multiday"
    assert_select "div#timesheet.singleday", false
    assert_select "div.timeslice-form", false
    assert_select "ul#expand-collapse-controls"
  end

  def test_should_assign_active_tasks
    UserSession.create(users(:one))
    get :index
    assert_not_nil assigns(:tasks)
    assert_equal 2, assigns(:tasks).length
  end

  def test_should_get_index_with_todays_date_by_default
    UserSession.create(users(:one))
    get :index
    assert_not_nil assigns(:date)
    assert_equal Date.today, assigns(:date), "assigns todays date by default"
  end

  def test_should_set_start_and_finished_time_on_empty_timesheet
    UserSession.create(users(:one))
    get :index, :date => '2009-11-16'
    assert_response :success
    assert_not_nil assigns(:timeslice)
    assert_equal Time.zone.parse('2009-11-16 08:00:00'), assigns(:timeslice).started,
      "sets timeslice started time to 08:00:00 on empty timesheet"
    assert_equal Time.zone.parse('2009-11-16 08:15:00'), assigns(:timeslice).finished,
      "sets timeslice finished time to 08:15:00 on empty timesheet"
  end

  def test_should_assign_timeslices_from_existing_timesheet
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14'
    assert_response :success
    assert_not_nil assigns(:timeslices)
    assert_equal 2, assigns(:timeslices).length, 
      "Returns two timeslices from existing timesheet"
  end

  def test_should_assign_timeslices_from_timesheet_spanning_multiple_dates
    UserSession.create(users(:two))
    get :index, :date => '2009-11-12', :end_date => '2009-11-14'
    assert_response :success
    assert_not_nil assigns(:timeslices)
    assert_equal 3, assigns(:timeslices).length, 
      "Returns three timeslices from timesheet spanning multiple days"
  end

  def test_should_set_start_and_finished_time_following_from_last_task_on_populated_timesheet
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14'
    assert_response :success
    assert_not_nil assigns(:timeslice)
    assert_equal Time.zone.parse('2009-11-14 23:00:00'), assigns(:timeslice).started,
      "sets timeslice started time to 23:00:00 on existing timesheet"
    assert_equal Time.zone.parse('2009-11-14 23:15:00'), assigns(:timeslice).finished,
      "sets timeslice finished time to 23:15:00 on existing timesheet"
  end

  def test_should_get_index_for_specific_task_and_subtasks
    UserSession.create(users(:two))
    get :index, :task_id => tasks(:two).id
    assert_response :success
    assert_not_nil assigns(:timeslices)
    assert_not_nil assigns(:date)
    assert_not_nil assigns(:end_date)
    assert_equal assigns(:date), assigns(:timeslices).first.date
    #assert_equal assigns(:end_date), assigns(:timeslices).last.date
    assert_equal 3, assigns(:timeslices).length
  end

  def test_should_get_index_for_specific_task_and_subtasks_by_date
    UserSession.create(users(:two))
    get :index, :task_id => tasks(:two).id, :date => '2009-11-14'
    assert_response :success
    assert_not_nil assigns(:timeslices)
    assert_not_nil assigns(:date)
    assert_not_nil assigns(:end_date)
    assert_equal 2, assigns(:timeslices).length
  end

  def test_should_get_index_in_xml_format
    UserSession.create(users(:one))
    get :index, :format => :xml
    assert_not_nil assigns(:timeslices)
  end

  def test_should_get_index_in_csv_format
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14', :format => 'csv'
    assert_not_nil assigns(:timeslices)
    assert_equal 2, assigns(:timeslices).length
    assert_equal 'text/csv; charset=utf-8',
      @response.headers['Content-Type'], 'Content type is CSV'
    assert_equal 'attachment; filename="2009-11-14.csv"',
      @response.headers['Content-Disposition'], 'Filename is 2009-11-14.csv'
  end

  def test_should_get_multi_day_index_in_csv_format
    UserSession.create(users(:one))
    get :index, :date => '2009-11-12', :end_date => '2009-11-14', 
                :format => 'csv'
    assert_not_nil assigns(:timeslices)
    assert_equal 2, assigns(:timeslices).length
    assert_equal 'text/csv; charset=utf-8',
      @response.headers['Content-Type'], 'Content type is CSV'
    assert_equal 'attachment; filename="2009-11-12_2009-11-14.csv"',
      @response.headers['Content-Disposition'], 
      'Filename is 2009-11-12_2009-11-14.csv'
  end

  def test_should_get_index_for_specific_task_in_csv_format
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14', :task_id => tasks(:one).id,
        :format => 'csv'
    assert_not_nil assigns(:timeslices)
    assert_equal 2, assigns(:timeslices).length
    assert_equal 'text/csv; charset=utf-8',
      @response.headers['Content-Type'], 'Content type is CSV'
    assert_equal "attachment; filename=\"#{tasks(:one).safe_name}-2009-11-14.csv\"",
      @response.headers['Content-Disposition'], "Filename is #{tasks(:one).safe_name}-2009-11-14.csv"
  end

  def test_should_get_index_for_specific_task_and_subtasks_in_csv_format
    UserSession.create(users(:two))
    get :index, :date => '2009-11-14', :task_id => tasks(:two).id,
        :format => 'csv'
    assert_not_nil assigns(:timeslices)
    assert_equal 2, assigns(:timeslices).length
    assert_equal 'text/csv; charset=utf-8',
      @response.headers['Content-Type'], 'Content type is CSV'
    assert_equal "attachment; filename=\"#{tasks(:two).safe_name}-2009-11-14.csv\"",
      @response.headers['Content-Disposition'], "Filename is #{tasks(:two).safe_name}-2009-11-14.csv"
  end

  def test_should_assign_total_duration
    UserSession.create(users(:one))
    get :index, :date => '2009-11-14'
    assert_response :success
    assert_equal 7200, assigns(:total_duration), 'assigns total timeslice duration for timesheet'
  end

  def test_should_get_new
    UserSession.create(users(:one))
    get :new, :task_id => tasks(:one).id
    assert_response :success
  end

  def test_should_create_timeslice
    UserSession.create(users(:one))

    # Create from timeslice/_form partial
    assert_difference('Timeslice.count') do
      post :create,  :date => '2009-11-15',
                    :timeslice => { 
                      :task_id => tasks(:one).id,
                      :started_time => '15:00',
                      :finished_time => '16:00'
                    }
    end
    assert_not_nil assigns(:timeslice)
    assert_equal Date.parse('2009-11-15'),assigns(:timeslice).started.to_date,
                  "assigns timeslice to correct date"
  end

  # If task[name] is not empty, create a new task with parent id of
  # timeslice[task_id]
  def test_should_create_timeslice_and_task
    UserSession.create(users(:one))
    assert_difference(['Timeslice.count','Task.count']) do
      post :create, :date => '2009-11-15',
                    :task => {
                      :name => 'Dummy task',
                    },
                    :timeslice => { 
                      :task_id => tasks(:one).id,
                      :started_time => '15:00',
                      :finished_time => '16:00'
                    }
    end
    assert_not_nil assigns(:task)
    assert_equal tasks(:one).id, assigns(:task).parent_id,
      "assigns the correct parent id to new task"
    assert_equal 'Dummy task', assigns(:task).name
  end

  def test_should_create_timeslice_and_task_at_root_level
    UserSession.create(users(:one))

    assert_difference(['Timeslice.count','Task.count']) do
      post :create, :date => '2009-11-15',
                    :task => {
                      :name => 'Dummy task',
                    },
                    :timeslice => { 
                      :task_id => '',
                      :started_time => '15:00',
                      :finished_time => '16:00'
                    }
    end
    assert_not_nil assigns(:task)
    assert assigns(:task).root?, "task is a root level task"
    assert_equal 'Dummy task', assigns(:task).name
  end

  def test_should_create_timeslice_and_multiple_tasks
    UserSession.create(users(:one))
    assert_difference 'Task.count', 2 do
      post :create, :date => '2009-11-15',
                    :task => {
                      :name => 'Task 1:Task 2',
                    },
                    :timeslice => { 
                      :task_id => tasks(:one).id,
                      :started_time => '15:00',
                      :finished_time => '16:00'
                    }
    end
    assert_not_nil assigns(:task)
    assert_equal 'Task 2', assigns(:task).name
    assert_equal 'Task 1', assigns(:task).parent.name,
      "assigns the correct parent to the second new task"
    assert_equal tasks(:one), assigns(:task).parent.parent,
      "assigns the correct parent id to the first new task"
  end

  def test_should_create_from_ajax
    UserSession.create(users(:one))
    xhr :post, :create, :date => '2009-11-14',
      :timeslice => { 
        :task_id => tasks(:one).id, 
        :started_time => '11:00',
        :finished_time => '12:00'
      }
    assert_not_nil assigns(:timeslice)
    assert_not_nil assigns(:timeslices)
    assert_equal 3, assigns(:timeslices).length,
      "assigns array of timeslices for the day"
    assert_not_nil assigns(:tasks)
  end

  # The AJAX insert requires an @next variable when there is an existing
  # timeslice on the same day at a later time
  def test_should_set_next_if_existing_on_same_day
    UserSession.create(users(:one))
    xhr :post, :create,
                  :date => '2009-11-14',
                  :timeslice => { 
                    :task_id => tasks(:one).id, 
                    :started_time => '11:00',
                    :finished_time => '12:00'
                  }
    assert_not_nil assigns(:next)
    assert_not_nil assigns(:timeslices)
    assert_equal 3, assigns(:timeslices).length
    assert_equal timeslices(:one), assigns(:next),
      "assigns next timeslice to @next"
  end

  def test_should_not_set_next_if_not_existing_on_same_day
    UserSession.create(users(:one))
    xhr :post, :create,
                  :date => '2009-11-14',
                  :timeslice => { 
                    :task_id => tasks(:one).id, 
                    :started_time => '23:00',
                    :finished_time => '23:30'
                  }
    assert_nil assigns(:next), "does not assign @next on last timeslice of day"
  end

  def test_should_assign_timeslice_with_blank_task_on_empty_day
    UserSession.create(users(:one))
    get :index, :date => '2009-11-15'
    assert_response :success
    assert_not_nil assigns(:timeslice)
    assert_nil assigns(:timeslice).task
  end
  
  def test_should_set_default_timeslice_parent_of_previous_task
    UserSession.create(users(:one))
    get :index, :date => '2009-11-12'
    assert_response :success
    assert_not_nil assigns(:timeslice), "assigns a timeslice"
    assert_equal timeslices(:three).task.parent, assigns(:timeslice).task, 
      "assigns @timeslice as the parent of the last task worked on for an active day sheet"
  end

  def test_should_get_edit
    UserSession.create(users(:one))
    get :edit, :id => timeslices(:one).id
    assert_response :success
  end

  def test_should_not_get_edit_for_other_users_timeslice
    UserSession.create(users(:one))
    get :edit, :id => timeslices(:four).id
    assert_response :missing
  end

  def test_should_update_timeslice
    UserSession.create(users(:one))
    put :update,  :id => timeslices(:one).id,
                  :timeslice => {
                      :started => '2009-11-14 14:00:00',
                      :finished => '2009-11-14 15:00:00'
                  }
    assert_not_nil assigns(:timeslice)
    assert_redirected_to timesheet_url(assigns(:timeslice).date)
  end

  def test_should_not_update_another_users_timeslice
    UserSession.create(users(:one))
    put :update,  :id => timeslices(:four).id,
                  :timeslice => {
                      :started => '2009-11-14 14:00:00',
                      :finished => '2009-11-14 15:00:00'
                  }
    assert_response :missing
  end

  def test_should_destroy_timeslice
    UserSession.create(users(:one))
    assert_difference('Timeslice.count', -1) do
      delete :destroy, :id => timeslices(:one).id
    end
  end

  def test_should_not_destroy_another_users_timeslice
    UserSession.create(users(:one))
    assert_no_difference('Timeslice.count') do
      delete :destroy, :id => timeslices(:four).id
    end
  end

  def test_should_set_time_zone_for_user
    users(:one).time_zone = 'Kamchatka'
    UserSession.create(users(:one))
    get :index
    assert_equal ActiveSupport::TimeZone['Kamchatka'], Time.zone,
                  'sets time zone for current user'
  end
end
