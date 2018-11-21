//===--- SymbolCollector.h ---------------------------------------*- C++-*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#ifndef LLVM_CLANG_TOOLS_EXTRA_CLANGD_INDEX_SYMBOL_COLLECTOR_H
#define LLVM_CLANG_TOOLS_EXTRA_CLANGD_INDEX_SYMBOL_COLLECTOR_H

#include "CanonicalIncludes.h"
#include "Index.h"
#include "clang/AST/ASTContext.h"
#include "clang/AST/Decl.h"
#include "clang/Basic/SourceLocation.h"
#include "clang/Basic/SourceManager.h"
#include "clang/Index/IndexDataConsumer.h"
#include "clang/Index/IndexSymbol.h"
#include "clang/Sema/CodeCompleteConsumer.h"
#include "llvm/ADT/DenseMap.h"
#include <functional>

namespace clang {
namespace clangd {

/// \brief Collect declarations (symbols) from an AST.
/// It collects most declarations except:
/// - Implicit declarations
/// - Anonymous declarations (anonymous enum/class/struct, etc)
/// - Declarations in anonymous namespaces
/// - Local declarations (in function bodies, blocks, etc)
/// - Declarations in main files
/// - Template specializations
/// - Library-specific private declarations (e.g. private declaration generated
/// by protobuf compiler)
///
/// See also shouldCollectSymbol(...).
///
/// Clients (e.g. clangd) can use SymbolCollector together with
/// index::indexTopLevelDecls to retrieve all symbols when the source file is
/// changed.
class SymbolCollector : public index::IndexDataConsumer {
public:
  struct Options {
    /// When symbol paths cannot be resolved to absolute paths (e.g. files in
    /// VFS that does not have absolute path), combine the fallback directory
    /// with symbols' paths to get absolute paths. This must be an absolute
    /// path.
    std::string FallbackDir;
    /// Specifies URI schemes that can be used to generate URIs for file paths
    /// in symbols. The list of schemes will be tried in order until a working
    /// scheme is found. If no scheme works, symbol location will be dropped.
    std::vector<std::string> URISchemes = {"file"};
    bool CollectIncludePath = false;
    /// If set, this is used to map symbol #include path to a potentially
    /// different #include path.
    const CanonicalIncludes *Includes = nullptr;
    // Populate the Symbol.References field.
    bool CountReferences = false;
    /// The symbol ref kinds that will be collected.
    /// If not set, SymbolCollector will not collect refs.
    /// Note that references of namespace decls are not collected, as they
    /// contribute large part of the index, and they are less useful compared
    /// with other decls.
    RefKind RefFilter = RefKind::Unknown;
    /// If set to true, SymbolCollector will collect all refs (from main file
    /// and included headers); otherwise, only refs from main file will be
    /// collected.
    /// This flag is only meaningful when RefFilter is set.
    bool RefsInHeaders = false;
    // Every symbol collected will be stamped with this origin.
    SymbolOrigin Origin = SymbolOrigin::Unknown;
    /// Collect macros.
    /// Note that SymbolCollector must be run with preprocessor in order to
    /// collect macros. For example, `indexTopLevelDecls` will not index any
    /// macro even if this is true.
    bool CollectMacro = false;
    /// If this is set, only collect symbols/references from a file if
    /// `FileFilter(SM, FID)` is true. If not set, all files are indexed.
    std::function<bool(const SourceManager &, FileID)> FileFilter = nullptr;
  };

  SymbolCollector(Options Opts);

  /// Returns true is \p ND should be collected.
  /// AST matchers require non-const ASTContext.
  static bool shouldCollectSymbol(const NamedDecl &ND, ASTContext &ASTCtx,
                                  const Options &Opts);

  void initialize(ASTContext &Ctx) override;

  void setPreprocessor(std::shared_ptr<Preprocessor> PP) override {
    this->PP = std::move(PP);
  }

  bool
  handleDeclOccurence(const Decl *D, index::SymbolRoleSet Roles,
                      ArrayRef<index::SymbolRelation> Relations,
                      SourceLocation Loc,
                      index::IndexDataConsumer::ASTNodeInfo ASTNode) override;

  bool handleMacroOccurence(const IdentifierInfo *Name, const MacroInfo *MI,
                            index::SymbolRoleSet Roles,
                            SourceLocation Loc) override;

  SymbolSlab takeSymbols() { return std::move(Symbols).build(); }
  RefSlab takeRefs() { return std::move(Refs).build(); }

  void finish() override;

private:
  const Symbol *addDeclaration(const NamedDecl &, SymbolID);
  void addDefinition(const NamedDecl &, const Symbol &DeclSymbol);

  // All Symbols collected from the AST.
  SymbolSlab::Builder Symbols;
  // All refs collected from the AST.
  // Only symbols declared in preamble (from #include) and referenced from the
  // main file will be included.
  RefSlab::Builder Refs;
  ASTContext *ASTCtx;
  std::shared_ptr<Preprocessor> PP;
  std::shared_ptr<GlobalCodeCompletionAllocator> CompletionAllocator;
  std::unique_ptr<CodeCompletionTUInfo> CompletionTUInfo;
  Options Opts;
  using DeclRef = std::pair<SourceLocation, index::SymbolRoleSet>;
  // Symbols referenced from the current TU, flushed on finish().
  llvm::DenseSet<const NamedDecl *> ReferencedDecls;
  llvm::DenseSet<const IdentifierInfo *> ReferencedMacros;
  llvm::DenseMap<const NamedDecl *, std::vector<DeclRef>> DeclRefs;
  // Maps canonical declaration provided by clang to canonical declaration for
  // an index symbol, if clangd prefers a different declaration than that
  // provided by clang. For example, friend declaration might be considered
  // canonical by clang but should not be considered canonical in the index
  // unless it's a definition.
  llvm::DenseMap<const Decl *, const Decl *> CanonicalDecls;
  // Cache whether to index a file or not.
  llvm::DenseMap<FileID, bool> FilesToIndexCache;
};

} // namespace clangd
} // namespace clang
#endif
