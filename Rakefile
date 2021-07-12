desc 'Run Rubocop'
task 'lint' do
  sh 'bundle exec rubocop --parallel'
end

desc 'Build app as local container image'
task 'build:container' do
  sh 'docker build --no-cache -t branch-protection-enforcer-app .'
end

desc 'Run app as local container'
task 'run:container' do
  sh 'docker ps -aq ' \
     ' --filter name=branch-protection-enforcer-app ' \
     ' --filter status=running ' \
     ' | xargs --no-run-if-empty docker stop'

  sh 'docker ps -aq ' \
     ' --filter name=branch-protection-enforcer-app ' \
     ' | xargs --no-run-if-empty docker rm'

  sh 'docker run -d -it ' \
     " -v \"#{ENV['PWD']}\"/.env:/app/.env " \
     ' -p 3000:3000 ' \
     ' --name branch-protection-enforcer-app ' \
     ' branch-protection-enforcer-app'
end
