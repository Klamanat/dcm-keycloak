import { useState } from "react";
import type { PageProps } from "keycloakify/login/pages/PageProps";
import type { KcContext } from "../KcContext";
import type { I18n } from "../i18n";

type LoginKcContext = Extract<KcContext, { pageId: "login.ftl" }>;

export default function Login(props: PageProps<LoginKcContext, I18n>) {
    const { kcContext, i18n } = props;

    const { realm, url, usernameHidden, login, auth, social } = kcContext;
    const { registrationAllowed, resetPasswordAllowed } = realm;

    const { msg, msgStr } = i18n;

    const [isSubmitting, setIsSubmitting] = useState(false);

    return (
        <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-950 to-slate-900 flex items-center justify-center p-4">
            <div className="w-full max-w-md">

                {/* Logo / Brand */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-blue-600 mb-4 shadow-lg shadow-blue-600/30">
                        <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                        </svg>
                    </div>
                    <h1 className="text-2xl font-bold text-white">Welcome back</h1>
                    <p className="text-slate-400 text-sm mt-1">Sign in to your account</p>
                </div>

                {/* Card */}
                <div className="bg-white/5 backdrop-blur-sm border border-white/10 rounded-2xl p-8 shadow-2xl">

                    {/* Social providers */}
                    {social?.providers && social.providers.length > 0 && (
                        <div className="mb-6 space-y-2">
                            {social.providers.map(provider => (
                                <a
                                    key={provider.alias}
                                    href={provider.loginUrl}
                                    className="flex w-full items-center justify-center gap-3 rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm font-medium text-white hover:bg-white/10 transition-colors"
                                >
                                    {provider.iconClasses && (
                                        <i className={provider.iconClasses} aria-hidden="true" />
                                    )}
                                    <span>Continue with {provider.displayName}</span>
                                </a>
                            ))}
                            <div className="relative my-5">
                                <div className="absolute inset-0 flex items-center">
                                    <div className="w-full border-t border-white/10" />
                                </div>
                                <div className="relative flex justify-center text-xs">
                                    <span className="bg-transparent px-3 text-slate-500">or continue with email</span>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Form */}
                    <form
                        action={url.loginAction}
                        method="post"
                        onSubmit={() => setIsSubmitting(true)}
                        className="space-y-5"
                    >
                        {/* Username */}
                        {!usernameHidden && (
                            <div>
                                <label htmlFor="username" className="block text-sm font-medium text-slate-300 mb-1.5">
                                    {!realm.loginWithEmailAllowed
                                        ? msgStr("username")
                                        : !realm.registrationEmailAsUsername
                                          ? msgStr("usernameOrEmail")
                                          : msgStr("email")}
                                </label>
                                <input
                                    id="username"
                                    name="username"
                                    type="text"
                                    defaultValue={login.username ?? ""}
                                    autoFocus
                                    autoComplete="username"
                                    className="w-full rounded-xl bg-white/5 border border-white/10 px-4 py-3 text-sm text-white placeholder-slate-500 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-colors"
                                    placeholder="you@example.com"
                                />
                            </div>
                        )}

                        {/* Password */}
                        <div>
                            <div className="flex items-center justify-between mb-1.5">
                                <label htmlFor="password" className="block text-sm font-medium text-slate-300">
                                    {msg("password")}
                                </label>
                                {resetPasswordAllowed && (
                                    <a
                                        href={url.loginResetCredentialsUrl}
                                        className="text-xs text-blue-400 hover:text-blue-300 transition-colors"
                                    >
                                        {msg("doForgotPassword")}
                                    </a>
                                )}
                            </div>
                            <input
                                id="password"
                                name="password"
                                type="password"
                                autoComplete="current-password"
                                className="w-full rounded-xl bg-white/5 border border-white/10 px-4 py-3 text-sm text-white placeholder-slate-500 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20 transition-colors"
                                placeholder="••••••••"
                            />
                        </div>

                        {/* Remember me */}
                        {realm.rememberMe && !usernameHidden && (
                            <div className="flex items-center gap-2">
                                <input
                                    id="rememberMe"
                                    name="rememberMe"
                                    type="checkbox"
                                    defaultChecked={!!login.rememberMe}
                                    className="h-4 w-4 rounded border-white/20 bg-white/5 text-blue-600 focus:ring-blue-500/20"
                                />
                                <label htmlFor="rememberMe" className="text-sm text-slate-400">
                                    {msg("rememberMe")}
                                </label>
                            </div>
                        )}

                        <input type="hidden" name="credentialId" value={auth?.selectedCredential ?? ""} />

                        {/* Submit */}
                        <button
                            type="submit"
                            disabled={isSubmitting}
                            className="w-full rounded-xl bg-blue-600 px-4 py-3 text-sm font-semibold text-white hover:bg-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-transparent disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg shadow-blue-600/20 mt-2"
                        >
                            {isSubmitting ? (
                                <span className="flex items-center justify-center gap-2">
                                    <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
                                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                    </svg>
                                    Signing in...
                                </span>
                            ) : msgStr("doLogIn")}
                        </button>

                        {/* Register */}
                        {registrationAllowed && (
                            <p className="text-center text-sm text-slate-500 pt-1">
                                {msg("noAccount")}{" "}
                                <a href={url.registrationUrl} className="font-medium text-blue-400 hover:text-blue-300 transition-colors">
                                    {msg("doRegister")}
                                </a>
                            </p>
                        )}
                    </form>
                </div>
            </div>
        </div>
    );
}
