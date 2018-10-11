//===----------------------------------------------------------------------===//
//
//                   Interprocedural Dependency Checker
//
//===----------------------------------------------------------------------===//
//
//  Copyright (C) 2017-2018. rollrat. All Rights Reserved.
//
//===----------------------------------------------------------------------===//

#ifndef _DEPENDENCY_INFO_
#define _DEPENDENCY_INFO_

#include "llvm/Pass.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include <vector>

namespace llvm {

  class DependencyInstrInfo
  {
  public:

    typedef enum {
      Annotated = 0,
      Perpect = 1,
      Dominated = 2,
      Maybe = 3,
    } DependencyInstrType;

    DependencyInstrInfo(Instruction *I, Value *S,
      DependencyInstrType T) : target(I), type(T), source(S) { }

    Instruction *getInstruction() const {
      return target;
    }

    Value *getSource() const {
      return source;
    }

    void setSource(Value *source) {
      this->source = source;
    }

    DependencyInstrType getType() const {
      return type;
    }

    void setType(DependencyInstrType type) {
      this->type = type;
    }

    std::string getInfo() const 
    {
      std::string ret;
      ret.push_back('[');
      if (type == DependencyInstrType::Annotated)
        ret.append("Annotated");
      else if (type == DependencyInstrType::Perpect)
        ret.append("Perpect");
      else if (type == DependencyInstrType::Dominated)
        ret.append("Dominated");
      else
        ret.append("Maybe");
      ret.append(", Source: ");
      ret.append(source->getName());
      ret.push_back(']');
      return ret;
    }

  private:

    Value * source;
    Instruction *target;
    DependencyInstrType type;
  };

  class DependencyInstrInfoManager
  {
    //using InfoType = SmallVector<DependencyInstrInfo *, 16>;
    //InfoType vec;
    size_t sz;
    DependencyInstrInfo **arr;
  public:

    DependencyInstrInfoManager() {
        arr = new DependencyInstrInfo*[255];
        sz = 0;
    }

    bool Verify() const {

    }

    void doFolding() {
      /*InfoType tmp;
      for (auto DI : vec) {
        for (auto TDI : tmp) {
          if (TDI->getSource() == DI->getSource()) {
            if ((unsigned)DI->getType() < (unsigned)TDI->getType()) {
              TDI->setType(DI->getType());
            }
            goto NEXT;
          }
        }
        tmp.push_back(DI);
      NEXT:
        ;
      }
      vec = tmp;*/
    }

    void addInfo(DependencyInstrInfo *info) {
      errs() << "Start adding\n";
      //vec.push_back(info);
      arr[sz++] = info;
      errs() << "Add info\n";
    }

    DepdencyInstrInfo** begin() const {
      //return vec.begin();
      return arr;
    }
/*
    InfoType::const_iterator end() const {
      return vec.end();
    }*/
  };

  FunctionPass *createInterproceduralDependencyCheckPass();

}

#endif
