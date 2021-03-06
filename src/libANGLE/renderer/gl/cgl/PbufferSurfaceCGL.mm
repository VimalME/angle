//
// Copyright (c) 2015 The ANGLE Project Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//

// PBufferSurfaceCGL.cpp: an implementation of egl::Surface for PBuffers for the CLG backend,
//                      currently implemented using renderbuffers

#include "libANGLE/renderer/gl/cgl/PbufferSurfaceCGL.h"

#include "common/debug.h"
#include "libANGLE/renderer/gl/FunctionsGL.h"
#include "libANGLE/renderer/gl/FramebufferGL.h"
#include "libANGLE/renderer/gl/RendererGL.h"
#include "libANGLE/renderer/gl/StateManagerGL.h"

namespace rx
{

PbufferSurfaceCGL::PbufferSurfaceCGL(const egl::SurfaceState &state,
                                     RendererGL *renderer,
                                     EGLint width,
                                     EGLint height,
                                     const FunctionsGL *functions)
    : SurfaceGL(state, renderer),
      mWidth(width),
      mHeight(height),
      mFunctions(functions),
      mStateManager(renderer->getStateManager()),
      mRenderer(renderer),
      mFramebuffer(0),
      mColorRenderbuffer(0),
      mDSRenderbuffer(0)
{
}

PbufferSurfaceCGL::~PbufferSurfaceCGL()
{
    if (mFramebuffer != 0)
    {
        mFunctions->deleteFramebuffers(1, &mFramebuffer);
        mFramebuffer = 0;
    }

    if (mColorRenderbuffer != 0)
    {
        mFunctions->deleteRenderbuffers(1, &mColorRenderbuffer);
        mColorRenderbuffer = 0;
    }
    if (mDSRenderbuffer != 0)
    {
        mFunctions->deleteRenderbuffers(1, &mDSRenderbuffer);
        mDSRenderbuffer = 0;
    }
}

egl::Error PbufferSurfaceCGL::initialize(const egl::Display *display)
{
    mFunctions->genRenderbuffers(1, &mColorRenderbuffer);
    mStateManager->bindRenderbuffer(GL_RENDERBUFFER, mColorRenderbuffer);
    mFunctions->renderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, mWidth, mHeight);

    mFunctions->genRenderbuffers(1, &mDSRenderbuffer);
    mStateManager->bindRenderbuffer(GL_RENDERBUFFER, mDSRenderbuffer);
    mFunctions->renderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, mWidth, mHeight);

    mFunctions->genFramebuffers(1, &mFramebuffer);
    mStateManager->bindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
    mFunctions->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER,
                                        mColorRenderbuffer);
    mFunctions->framebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT,
                                        GL_RENDERBUFFER, mDSRenderbuffer);

    return egl::NoError();
}

egl::Error PbufferSurfaceCGL::makeCurrent()
{
    return egl::NoError();
}

egl::Error PbufferSurfaceCGL::swap(const egl::Display *display)
{
    return egl::NoError();
}

egl::Error PbufferSurfaceCGL::postSubBuffer(EGLint x, EGLint y, EGLint width, EGLint height)
{
    return egl::NoError();
}

egl::Error PbufferSurfaceCGL::querySurfacePointerANGLE(EGLint attribute, void **value)
{
    UNIMPLEMENTED();
    return egl::NoError();
}

egl::Error PbufferSurfaceCGL::bindTexImage(gl::Texture *texture, EGLint buffer)
{
    UNIMPLEMENTED();
    return egl::NoError();
}

egl::Error PbufferSurfaceCGL::releaseTexImage(EGLint buffer)
{
    UNIMPLEMENTED();
    return egl::NoError();
}

void PbufferSurfaceCGL::setSwapInterval(EGLint interval)
{
}

EGLint PbufferSurfaceCGL::getWidth() const
{
    return mWidth;
}

EGLint PbufferSurfaceCGL::getHeight() const
{
    return mHeight;
}

EGLint PbufferSurfaceCGL::isPostSubBufferSupported() const
{
    UNIMPLEMENTED();
    return EGL_FALSE;
}

EGLint PbufferSurfaceCGL::getSwapBehavior() const
{
    return EGL_BUFFER_PRESERVED;
}

FramebufferImpl *PbufferSurfaceCGL::createDefaultFramebuffer(const gl::FramebufferState &state)
{
    // TODO(cwallez) assert it happens only once?
    return new FramebufferGL(mFramebuffer, state, mFunctions, mRenderer->getWorkarounds(),
                             mRenderer->getBlitter(), mStateManager);
}

}  // namespace rx
