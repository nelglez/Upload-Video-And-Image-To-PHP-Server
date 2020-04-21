//
//  ViewController.swift
//  UploadToServer
//
//  Created by Nelson Gonzalez on 4/20/20.
//  Copyright © 2020 Nelson Gonzalez. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, URLSessionDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var pickImageButton: UIButton!
    @IBOutlet var pickVideoButton: UIButton!
 
    var dataPath: URL?
    var myImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if let videoURL = info[.mediaURL] as? URL {
            print(videoURL)
            
            imageView.image = self.thumbnailImageForFileUrl(videoURL)
            myImage = self.thumbnailImageForFileUrl(videoURL)
            
            let videoData = try? Data(contentsOf: videoURL)
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory: URL = URL(fileURLWithPath: paths[0])
            let  saveFileName = "video-\(UUID().uuidString).mp4"
            dataPath = documentsDirectory.appendingPathComponent(saveFileName)
            guard let dataPath = dataPath else { return }
            try! videoData?.write(to: dataPath, options: [])
            print("Saved to " + dataPath.absoluteString)
            encodeVideo(videoURL: dataPath)
            
            self.dismiss(animated: true, completion: nil)
            
            
            
        } else {
            
            imageView.image = info[.originalImage] as? UIImage
            myImage = info[.originalImage] as? UIImage
            imageView.backgroundColor = UIColor.clear
            self.dismiss(animated: true, completion: nil)
            HITtheSERVER()
        }
        
    }
    
    func encodeVideo(videoURL: URL)  {
        let avAsset = AVURLAsset(url: videoURL, options: nil)
        
        let startDate = Date()
        
        
        //Create Export session
        let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough)
        
        
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let saveFileName = "video-\(UUID().uuidString).mp4"
        guard let myDocumentPath = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent(saveFileName)?.absoluteString else { return}
        //        let url = NSURL(fileURLWithPath: myDocumentPath)
        
        let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
        
        guard let filePath = documentsDirectory2.appendingPathComponent("rendered-Video.mp4") else { return }
        deleteFile(filePath: filePath)
        
        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: myDocumentPath) {
            do {
                try FileManager.default.removeItem(atPath: myDocumentPath)
            }
            catch let error {
                print(error)
            }
        }
        
        
        exportSession?.outputURL = filePath
        exportSession?.outputFileType = AVFileType.mp4
        exportSession?.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession?.timeRange = range
        
        exportSession!.exportAsynchronously(completionHandler: {() -> Void in
            switch exportSession!.status {
            case .failed:
                print("%@",exportSession!.error!)
            case .cancelled:
                print("Export canceled")
            case .completed:
                //Video conversion finished
                let endDate = Date()
                
                let time = endDate.timeIntervalSince(startDate)
                print(time)
                print("Successful!")
                print(exportSession!.outputURL!)
                
                guard  let mediaPath = exportSession?.outputURL else { return }
                
                self.uploadVideo(mediaPath)
                
            default:
                break
            }
            
        })
        
        
    }
    
    func deleteFile(filePath: URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
            
            print("Deleted file at: \(filePath)")
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    func thumbnailImageForFileUrl(_ url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        time.value = min(time.value, 2)
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch let error as NSError {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func HITtheSERVER() {
        
        
        guard let myImage = myImage else { return }
        
        
        let imageData = myImage.jpegData(compressionQuality: 0.5)
        if(imageData == nil ) { return }
        
        guard let myImageData = imageData else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let stringOfDateTimeStamp = formatter.string(from: Date())
        //        print("Date time stamp String: \(stringOfDateTimeStamp)")
        let remoteName = "IMG_\(stringOfDateTimeStamp)"+".png"
        let myUrl = URL(string: "https://www.ultimate-teenchat.com/test-app/uploadimage.php")!
        let request = NSMutableURLRequest(url: myUrl)
        request.httpMethod = "POST"
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let fname = remoteName
        let mimetype = "image/png"
        
        body.append("--\(boundary)\r\n".data(
            using: String.Encoding.utf8,
            allowLossyConversion: false)!)
        body.append("Content-Disposition:form-data; name=\"test\"\r\n\r\n".data(
            using: String.Encoding.utf8,
            allowLossyConversion: false)!)
        body.append("hi\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        
        body.append(myImageData)
        body.append("\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        
        request.httpBody = body
        
        
        let session = Foundation.URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) {
            (
            data, response, error) in
            
            guard let _:NSData = data as NSData?, let _:URLResponse = response, error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print(dataString as Any)
            
            self.myImage = nil
            
        }
        
        task.resume()
        
        
        
        
    }
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    
    
    
    func uploadVideo(_ mediaPath: URL){
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let stringOfDateTimeStamp = formatter.string(from: Date())
        
        
        
        guard let url = URL(string: "https://www.ultimate-teenchat.com/test-app/uploadimage.php") else {
            return
        }
        
        var movieData: Data?
        do {
            movieData = try Data(contentsOf: mediaPath, options: Data.ReadingOptions.alwaysMapped)
        } catch _ {
            movieData = nil
            return
        }
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = generateBoundaryString()
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        let remoteName = "MOV_\(stringOfDateTimeStamp).mp4"
        let fname = remoteName
        let mimetype = "video/mp4"
        
        body.append("--\(boundary)\r\n".data(
            using: String.Encoding.utf8,
            allowLossyConversion: false)!)
        body.append("Content-Disposition:form-data; name=\"test\"\r\n\r\n".data(
            using: String.Encoding.utf8,
            allowLossyConversion: false)!)
        body.append("hi\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        
        body.append(movieData!)
        body.append("\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8,allowLossyConversion: false)!)
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        
        request.httpBody = body
        
        let session = Foundation.URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) {
            (
            data, response, error) in
            
            guard let _:NSData = data as NSData?, let _:URLResponse = response, error == nil else {
                print("error")
                return
            }
            
            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print(dataString as Any)
            
        }
        
        task.resume()
        
        deleteFile(filePath: mediaPath)
        guard let dataPath = dataPath else { return }
        deleteFile(filePath: dataPath)
        
        HITtheSERVER()
    }
    
    
    
    @IBAction func pickImageButtonPressed(_ sender: UIButton) {
        let myPickerController = UIImagePickerController()
        myPickerController.delegate = self
        myPickerController.sourceType = .photoLibrary
        
        myPickerController.mediaTypes = ["public.image"]
        
        self.present(myPickerController, animated: true, completion: nil)
    }
    
    @IBAction func pickVideoButtonPressed(_ sender: UIButton) {
        let myPickerController = UIImagePickerController()
        myPickerController.delegate = self
        myPickerController.sourceType = .photoLibrary
        
        myPickerController.mediaTypes = ["public.movie"]
        
        self.present(myPickerController, animated: true, completion: nil)
    }
    
    
    
}

