require 'faker'
require 'active_record'
require './seeds'
require 'kaminari'
require 'sinatra/base'
require 'graphiti'
require 'graphiti/adapters/active_record'

class ApplicationResource < Graphiti::Resource
  self.abstract_class = true
  self.adapter = Graphiti::Adapters::ActiveRecord
  self.base_url = 'http://localhost:4567'
  self.endpoint_namespace = '/api/v1'
  self.validate_endpoints = false
end

class DepartmentResource < ApplicationResource
  self.model = Department
  self.type = :departments

  attribute :name, :string
end

class EmployeeResource < ApplicationResource
  self.model = Employee
  self.type = :employees

  self.default_page_size = 10
  self.max_page_size = 100

  attribute :first_name, :string
  attribute :last_name, :string
  attribute :age, :integer
  attribute :position, :string
  attribute :department_name, :string, writable: false

  def department_name
    @object.department.name
  end

  # filters
  filter :first_name, :string do
    eq { |scope, value| scope.where('lower(first_name) LIKE ?', "%#{value.first.downcase}%") }
  end
  
  filter :last_name, :string do
    eq { |scope, value| scope.where('lower(last_name) LIKE ?', "%#{value.first.downcase}%") }
  end
  
  filter :position, :string
  filter :age, :integer

  # filter по имени департамента for future use
  filter :department_name, :string do
    eq { |scope, value| 
      scope.joins(:department).where('lower(departments.name) LIKE ?', "%#{value.downcase}%") 
    }
  end

  # sorting
  sort :first_name, :asc
  sort :last_name, :asc
  sort :age, :asc
  sort :position, :asc
end

Graphiti.setup!

class EmployeeDirectoryApp < Sinatra::Application
  configure do
    mime_type :jsonapi, 'application/vnd.api+json'
  end

  before do
    content_type :jsonapi
  end

  after do
    ActiveRecord::Base.connection_handler.clear_active_connections!
  end

  # get all departments
  get '/api/v1/departments' do
    departments = DepartmentResource.all(params)
    departments.to_jsonapi
  end

  # get one department by id
  get '/api/v1/departments/:id' do
    department = DepartmentResource.find(params[:id])
    department.to_jsonapi
  end

  # get all employees with pagination
  get '/api/v1/employees' do
    #I've tryed to use kaminari for pagination, but it doesn't work with graphiti
    all_employees = Employee.all
    total_count = all_employees.count
    
    page_number = (params.dig(:page, :number) || 1).to_i
    page_size = (params.dig(:page, :size) || EmployeeResource.default_page_size).to_i
    
    page_size = [page_size, EmployeeResource.max_page_size].min
    
    params[:page] ||= {}
    params[:page][:number] = page_number
    params[:page][:size] = page_size
    
    scope = EmployeeResource.all(params)
    
    total_pages = (total_count.to_f / page_size).ceil
    
    meta = {
      page: page_number,
      per_page: page_size,
      total_items: total_count,
      total_pages: total_pages
    }
    
    jsonapi_response = scope.to_jsonapi
    jsonapi_hash = JSON.parse(jsonapi_response, symbolize_names: true)
    
    jsonapi_hash[:meta] = meta
    
    jsonapi_hash.to_json
  end

  # get one employee by id
  get '/api/v1/employees/:id' do
    employee = EmployeeResource.find(params[:id])
    employee.to_jsonapi
  end
end