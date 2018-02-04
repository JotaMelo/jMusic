platform :ios, "9.3"

def sharedPods
    pod "SDWebImage"
end

target "jMusic" do
    sharedPods
    pod "iRate", :git => "https://github.com/nicklockwood/iRate.git"
    pod "UIScrollView-InfiniteScroll", "~> 1.0.0"
    pod "MBProgressHUD"
    pod "BEMCheckBox"
end

target "jMusicTests" do
    sharedPods
end

inhibit_all_warnings!
use_frameworks!
