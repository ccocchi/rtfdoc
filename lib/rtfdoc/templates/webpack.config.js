const path = require('path');
const os = require('os');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

const devMode = process.env.NODE_ENV != 'production'

module.exports = {
  mode: devMode ? "development" : "production",
  entry: __dirname + "/src/js/index.js",
  output: {
    filename: devMode ? "main.js" : "main.[contenthash].js",
    path: __dirname + "/dist",
  },
  plugins: [
    new CleanWebpackPlugin({ cleanStaleWebpackAssets: !devMode }),
    new MiniCssExtractPlugin({
      filename: devMode ? '[name].css' : '[name].[contenthash].css'
    }),
    new HtmlWebpackPlugin({
      template: os.tmpdir() + "/rtfdoc_output.html"
    })
  ],
  devtool: devMode ? "inline-source-map" : "source-map",
  resolve: {
    modules: [path.resolve(__dirname, 'node_modules')]
  },
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          MiniCssExtractPlugin.loader,
          // Translates CSS into CommonJS
          'css-loader',
          // Compiles Sass to CSS
          'sass-loader',
        ]
      }
    ]
  }
};
