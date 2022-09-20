import Foundation

public final class ListState: ObservableObject {
    @Published public  var isLoading = false
    
    public init() { }
}
