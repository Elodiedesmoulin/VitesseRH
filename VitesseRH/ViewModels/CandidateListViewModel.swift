//
//  CandidateListViewModel.swift
//  VitesseRH
//
//  Created by Elo on 06/01/2025.
//

import Foundation
import Combine

class CandidateListViewModel: ObservableObject {
    @Published var candidates = [Candidate]()
    @Published var filteredCandidates = [Candidate]()
    @Published var isEditMode: Bool = false
    @Published var selectedCandidates = Set<Candidate>()
    @Published var errorMessage: String?
    
    @Published var searchText: String = ""
    @Published var showFavoritesOnly: Bool = false
    
    private let service: VitesseRHService
    private var token: String
    private var cancellables = Set<AnyCancellable>()
    
    init(service: VitesseRHService = VitesseRHService(), token: String) {
        self.service = service
        self.token = token
        fetchCandidates()
    }
    
    func fetchCandidates() {
        Task {
            do {
                let candidates = try await service.getCandidates(token: token)
                DispatchQueue.main.async {
                    self.candidates = candidates
                    self.filteredCandidates = candidates

                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load candidates."
                }
            }
        }
    }
    
    func toggleFavorite(for candidate: Candidate) {
        if let index = candidates.firstIndex(where: { $0.id == candidate.id }) {
            candidates[index].isFavorite.toggle()
            filterCandidates(by: searchText, showFavoritesOnly: showFavoritesOnly)
        }
        
        Task {
            do {
                try await service.toggleFavoriteStatus(token: token, candidateId: candidate.id)
            } catch {
                DispatchQueue.main.async {
                    if let index = self.candidates.firstIndex(where: { $0.id == candidate.id }) {
                        self.candidates[index].isFavorite.toggle()
                        self.filterCandidates(by: self.searchText, showFavoritesOnly: self.showFavoritesOnly)
                    }
                    self.errorMessage = "Failed to update favorite status."
                }
            }
        }
    }
    
    
    func filterCandidates(by searchText: String, showFavoritesOnly: Bool) {
        filteredCandidates = candidates.filter { candidate in
            let matchesSearchText = searchText.isEmpty || candidate.firstName.lowercased().contains(searchText.lowercased()) || candidate.lastName.lowercased().contains(searchText.lowercased())
            
            let matchesFavorites = !showFavoritesOnly || candidate.isFavorite
            
            return matchesSearchText && matchesFavorites
        }
    }
    
    
    func toggleEditMode() {
            isEditMode.toggle()
            selectedCandidates.removeAll()
        }

        func toggleSelection(for candidate: Candidate) {
            if selectedCandidates.contains(candidate) {
                selectedCandidates.remove(candidate)
            } else {
                selectedCandidates.insert(candidate)
            }
        }

    func deleteSelectedCandidates() {
        Task {
            do {
                for candidate in selectedCandidates {
                    try await service.deleteCandidate(token: token, candidateId: candidate.id)
                }
                selectedCandidates.removeAll()
                fetchCandidates()  
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete selected candidates."
                }
            }
        }
    }

}
