module.exports = {
  apps: [
    {
      name: 'foodjet-backend',
      script: './src/server.js',
      watch: false,
      env: {
        NODE_ENV: 'development'
      }
    }
  ]
}
