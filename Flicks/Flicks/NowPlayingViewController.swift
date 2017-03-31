//
//  FirstViewController.swift
//  Flicks
//
//  Created by Yan, Tristan on 3/28/17.
//  Copyright © 2017 Yan, Tristan. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class NowPlayingViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var movieSearchBar: UISearchBar!
    
    @IBOutlet weak var networkErrorView: UIView!
    
    @IBOutlet weak var alertImageView: UIImageView!
    
    @IBOutlet weak var networkErrorLabel: UILabel!
    
    let api_key = "0a870c2e3daf46a8b6099e99cb0ed595"
    
    var movies: [NSDictionary]?
    
    var searchActive: Bool = false
    
    var filteredMovies: [NSDictionary]?
    
    var networkConnected: Bool = true
    
    var sortWay:String = "now_playing" // 0 means now playing, which is default, 1 means top rate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        movieSearchBar.delegate = self

        // Do any additional setup after loading the view, typically from a nib.
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: .valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        
        
        MBProgressHUD.showAdded(to: tableView, animated: true)
        let url = URL(string:"https://api.themoviedb.org/3/movie/now_playing?language=en-US&api_key=\(api_key)")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: request,completionHandler: { (dataOrNil, response, error) in
            if let httpError = error {
                self.networkConnected = false
                self.networkErrorView.isHidden = false
                MBProgressHUD.hide(for: self.tableView, animated: true)
                print(httpError)
            } else {
                if let data = dataOrNil {
                    if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? NSDictionary {
                        self.movies = responseDictionary["results"] as? [NSDictionary]
//                        sleep(10)
                        MBProgressHUD.hide(for: self.tableView, animated: true)
                        self.tableView.reloadData()
                    }
                }
            }
        });
        task.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (networkConnected) {
            networkErrorView.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(searchActive) {
            return (filteredMovies?.count)!
        } else {
            if let movies = movies {
                return movies.count
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var movie: NSDictionary?
        
        if (searchActive) {
            movie = filteredMovies?[indexPath.row]
        } else {
            movie = movies?[indexPath.row]
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieTableViewCell
        cell?.titleLabel.text = movie?["title"] as? String
        cell?.content.text = movie?["overview"] as? String
        
        if let imageUriStr = movie?["poster_path"] as? String {
            let imageUrlStr = "https://image.tmdb.org/t/p/w500\(imageUriStr)"

            let imageRequest = URLRequest(url: URL(string: imageUrlStr)!)
            cell?.movieImage.setImageWith(imageRequest, placeholderImage: nil, success: { (imageRequest, response, image) in
                if response != nil {
                    cell?.movieImage.alpha = 0.0
                    cell?.movieImage.image = image
                    UIView.animate(withDuration: 1.0, animations: {() -> Void in
                        cell?.movieImage.alpha = 1.0
                    })
                } else {
                    cell?.movieImage.image = image
                }
            }, failure: { (imageRequest, response, error) in
                print(error)
            })
        }
        
        cell?.sizeToFit()
        
        return cell!
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredMovies = movies?.filter(){ (movie) -> Bool in
            if let movieTitle = movie["title"] as? String {
                let range = movieTitle.startIndex..<movieTitle.endIndex
                return movieTitle.range(of: searchText, options: .caseInsensitive, range: range, locale: Locale.current) != nil
            }
            return true
        }
        
        if (filteredMovies?.count == 0) {
            self.searchActive = false
        } else {
            self.searchActive = true
        }
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let target = segue.destination as? MovieDetailViewController
        let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
        let selected = self.movies?[(indexPath?.row)!]
        
        target?.movie = selected
    }
    
    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        MBProgressHUD.showAdded(to: tableView, animated: true)
        let url = URL(string:"https://api.themoviedb.org/3/movie/now_playing?language=en-US&api_key=\(api_key)")
        let request = URLRequest(url: url!)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: request,completionHandler: { (dataOrNil, response, error) in
            if let httpError = error {
                self.networkConnected = false
                self.networkErrorView.isHidden = false
                MBProgressHUD.hide(for: self.tableView, animated: true)
                print(httpError)
            } else {
                if let data = dataOrNil {
                    if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options:[]) as? NSDictionary {
                        self.movies = responseDictionary["results"] as? [NSDictionary]
                        //                        sleep(10)
                        MBProgressHUD.hide(for: self.tableView, animated: true)
                        self.networkConnected = true
                        self.networkErrorView.isHidden = true
                        self.tableView.reloadData()

                    }
                }
            }
            refreshControl.endRefreshing()
        });
        task.resume()
    }
}

