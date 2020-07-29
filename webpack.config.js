const path = require('path');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');

module.exports = {
  entry: ['./src/js/scroll.js', './build/application.css', './build/output.html'],
  output: {
    filename: 'main.[contenthash].js',
    path: path.resolve(__dirname, 'dist'),
  },
  plugins: [
    new CleanWebpackPlugin()
  ],
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          "file-loader?name=application.[contenthash].css",
          "extract-loader",
          {
            loader: "css-loader",
            options: { sourceMap: true }
          }
        ]
      },
      {
        test: /output\.html$/,
        use: [
          "file-loader?name=index.html",
          "extract-loader",
          {
            loader: "html-loader",
            options: {
              attributes: {
                list: [
                  {
                    tag: "link",
                    attribute: "href",
                    type: "src"
                  },
                  {
                    tag: "script",
                    attribute: "src",
                    type: "src"
                  }
                ]
              }
            }
          }
        ]
      }
    ]
  }
};
