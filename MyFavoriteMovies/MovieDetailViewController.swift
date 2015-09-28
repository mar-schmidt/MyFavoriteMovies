//
//  MovieDetailViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: MovieDetailViewController: UIViewController

class MovieDetailViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var unFavoriteButton: UIButton!

    var appDelegate: AppDelegate!
    var session: NSURLSession!
    
    var movie: Movie?
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Get the app delegate */
        appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        /* Get the shared URL session */
        session = NSURLSession.sharedSession()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let movie = movie {
            
            titleLabel.text = movie.title
            unFavoriteButton.hidden = true
            
            /* TASK A: Get favorite movies, then update the favorite buttons */
            /* 1. Set the parameters */
            let methodParameters = [
                "api_key": appDelegate.apiKey,
                "session_id": appDelegate.sessionID
            ]
            /* 2. Build the URL */
            let urlString = appDelegate.baseURLSecureString + "account/" + "\(appDelegate.userID!)" + "/favorite/movies" + appDelegate.escapedParameters(methodParameters)
            let url = NSURL(string: urlString)!
            print(url)
            
            /* 3. Configure the request */
            let request = NSMutableURLRequest(URL: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            /* 4. Make the request */
            let task = session.dataTaskWithRequest(request) { (data, response, error) in
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    print("getRequestToken: Print an error message")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                    if let response = response as? NSHTTPURLResponse {
                        print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                        
                    } else if let response = response {
                        print("Your request returned an invalid response! Response: \(response)!")
                        
                    } else {
                        print("Your request returned an invalid response!")
                        
                    }
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    print("No data was returned by the request!")
                    
                    return
                }
                
                /* 5. Parse the data */
                var parsedResult: AnyObject!
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
                    if let results = parsedResult["results"] as? [[String:AnyObject]] {
                        var isFavorite = false
                        let movies = Movie.moviesFromResults(results)
                        
                        for movie in movies {
                            if movie.id == self.movie!.id {
                                isFavorite = true
                            }
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            if isFavorite {
                                self.favoriteButton.hidden = true
                                self.unFavoriteButton.hidden = false
                            } else {
                                self.favoriteButton.hidden = false
                                self.unFavoriteButton.hidden = true
                            }
                        }
                    }
                } catch {
                    parsedResult = nil
                    print("Count not parse the data as JSON: '\(data)'")
                    
                    return
                }
            }
            
            /* 7. Start the request */
            task.resume()
        }

    
        /* TASK B: Get the poster image, then populate the image view */
        if let movie = movie, posterPath = movie.posterPath {
            
            /* 1B. Set the parameters */
            // There are none...
            
            /* 2B. Build the URL */
            let baseURL = NSURL(string: appDelegate.config.baseImageURLString)!
            let url = baseURL.URLByAppendingPathComponent("w342").URLByAppendingPathComponent(posterPath)
            
            /* 3B. Configure the request */
            let request = NSURLRequest(URL: url)
            
            /* 4B. Make the request */
            let task = session.dataTaskWithRequest(request) { (data, response, error) in
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    print("There was an error with your request: \(error)")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                    if let response = response as? NSHTTPURLResponse {
                        print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                    } else if let response = response {
                        print("Your request returned an invalid response! Response: \(response)!")
                    } else {
                        print("Your request returned an invalid response!")
                    }
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    print("No data was returned by the request!")
                    return
                }
                
                /* 5B. Parse the data */
                // No need, the data is already raw image data.
                
                /* 6B. Use the data! */
                if let image = UIImage(data: data) {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.posterImageView!.image = image
                    }
                } else {
                    print("Could not create image from \(data)")
                }
            }
            
            /* 7B. Start the request */
            task.resume()
        }
    }
    
    // MARK: Favorite Actions
    
    @IBAction func unFavoriteButtonTouchUpInside(sender: AnyObject) {
        
        /* TASK: Remove movie as favorite, then update favorite buttons */
        /* 1. Set the parameters */
        let methodParameters = [
            "api_key": appDelegate.apiKey,
            "session_id": appDelegate.sessionID,
        ]
        /* 2. Build the URL */
        let urlString = appDelegate.baseURLSecureString + "account/" + "\(appDelegate.userID!)" + "/favorite" + appDelegate.escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        print(url)
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params = "{\"media_type\": \"movie\",\"media_id\": \(self.movie!.id),\"favorite\": false}".dataUsingEncoding(NSUTF8StringEncoding)
        print(params)
        request.HTTPBody = params
    
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("getRequestToken: Print an error message")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                    
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                    
                } else {
                    print("Your request returned an invalid response!")
                    
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                
                return
            }
            
            /* 5. Parse the data */
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
                if (parsedResult["status_code"] as! Int == 13) {
                    print("Movie \(self.movie?.title) was successfully unfavorited");
                    dispatch_async(dispatch_get_main_queue()) {
                        self.favoriteButton.hidden = false;
                        self.unFavoriteButton.hidden = true;
                    }
                }
            } catch {
                parsedResult = nil
                print("Count not parse the data as JSON: '\(data)'")
                
                return
            }
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    @IBAction func favoriteButtonTouchUpInside(sender: AnyObject) {
        
        /* TASK: Remove movie as favorite, then update favorite buttons */
        /* 1. Set the parameters */
        let methodParameters = [
            "api_key": appDelegate.apiKey,
            "session_id": appDelegate.sessionID,
        ]
        /* 2. Build the URL */
        let urlString = appDelegate.baseURLSecureString + "account/" + "\(appDelegate.userID!)" + "/favorite" + appDelegate.escapedParameters(methodParameters)
        let url = NSURL(string: urlString)!
        print(url)
        
        /* 3. Configure the request */
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params = "{\"media_type\": \"movie\",\"media_id\": \(self.movie!.id),\"favorite\": true}".dataUsingEncoding(NSUTF8StringEncoding)
        print(params)
        request.HTTPBody = params
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("getRequestToken: Print an error message")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                    
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                    
                } else {
                    print("Your request returned an invalid response!")
                    
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                
                return
            }
            
            /* 5. Parse the data */
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! NSDictionary
                if (parsedResult["status_code"] as! Int == 12 || parsedResult["status_code"] as! Int == 1) {
                    print("Movie \(self.movie?.title) was successfully favorited");
                    dispatch_async(dispatch_get_main_queue()) {
                        self.favoriteButton.hidden = true;
                        self.unFavoriteButton.hidden = false;
                    }
                }
            } catch {
                parsedResult = nil
                print("Count not parse the data as JSON: '\(data)'")
                
                return
            }
        }
        
        /* 7. Start the request */
        task.resume()
    }
}
